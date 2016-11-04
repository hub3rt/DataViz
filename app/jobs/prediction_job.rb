class PredictionJob
	include SuckerPunch::Job
	workers 2

	def perform
		ActiveRecord::Base.connection_pool.with_connection do
			script = predict_script
			result = Rserve::Connection.new.eval(script).to_ruby
			if result
				championnat = Championnat.first
				curMatchday = Match.last.matchday+1
				for i in (0..result[0].length-1)
					Match.create(
					matchyear: "2016 - 2017",
					matchday: curMatchday,
					home_team: result[0][i],
					away_team: result[1][i],
					home_prevision: result[2][i]*100,
					draw_prevision: result[3][i]*100,
					away_prevision: result[4][i]*100,
					championnat: championnat
					)
				end
			end
			scriptOldPred = old_predscript
			resultOldPred = Rserve::Connection.new.eval(scriptOldPred).to_ruby
			if resultOldPred
					for i in (0..resultOldPred[0].length-1)
					Match.where(id: i + 1).update(
					home_prevision: result[2][i] * 100,
					draw_prevision: result[3][i] * 100,
					away_prevision: result[4][i] * 100,
					)
				end
			end
		end
	end

	private
	def predict_script
		<<-EOF

		#import data
		setwd("/home/hubert/dataViz/dataLigue1")	
		dataLigue1<-data.frame()
		for (i in 1:(length(list.files())-1))
		{
		  oneSeason<-read.csv(list.files()[i], sep=",", header=T)[1:380,2:7]
		  dataLigue1<-rbind(dataLigue1,oneSeason)
		}
		dataLigue1<-rbind(dataLigue1,read.csv(list.files()[length(list.files())], sep=",", header=T)[1:110,2:7])
		#remove levels ""
		dataLigue1$Date<-droplevels(dataLigue1$Date)
		dataLigue1$HomeTeam<-droplevels(dataLigue1$HomeTeam)
		dataLigue1$AwayTeam<-droplevels(dataLigue1$AwayTeam)
		dataLigue1$FTR<-droplevels(dataLigue1$FTR)
		#build teams indicator
		teams<-sort(unique(dataLigue1$HomeTeam))
		dataLigue1$home.team<-c()
		dataLigue1$away.team<-c()
		for(k in 1:nrow(dataLigue1)) 
		{
		  dataLigue1$home.team[k]<-match(dataLigue1$HomeTeam[k],teams)
		}
		for(k in 1:nrow(dataLigue1))
		{
		  dataLigue1$away.team[k]<-match(dataLigue1$AwayTeam[k],teams)
		}
		#initialize estimates
		mu<-0.001
		a<-rep(0.001,length(teams))
		b<-rep(0.001,length(teams))
		tau<-0.001
		theta<-c()
		for(i in 1:length(teams))
		{
		  theta<-c(theta,a[i],b[i])
		}
		theta<-c(theta,mu,tau)
		#create loglikelyhood function
		loglik.final<- function(theta,i,j,n.teams,home.goals,away.goals)
		{
		  a.i <- theta[2*i-1]
		  b.i <- theta[2*i]
		  a.j <- theta[2*j-1]
		  b.j <- theta[2*j]
		  mu  <- theta[2*n.teams+1]
		  tau <- theta[2*n.teams+2]
		  lambda.home <- exp(mu+ a.i + b.j + tau)
		  lambda.away <- exp(mu+ a.j + b.i)
		  loglik <- sum(dpois(home.goals,lambda.home,log=T)) + sum(dpois(away.goals,lambda.away,log=T))
		  return(-loglik) 
		}
		#calculate estimates
		n.teams<-length(teams)
		est.final<-optim(c(rep(0.001,length(theta))), loglik.final, 
		                 n.teams=length(teams), i=dataLigue1$home.team, j=dataLigue1$away.team, 
		                 home.goals=dataLigue1$FTHG, away.goals=dataLigue1$FTAG, method = "L-BFGS-B")
		#import next 10 games
		next.day<-data.frame(HomeTeam=c("Montpellier", "Monaco", "Angers", "Bordeaux", "Dijon", "Lyon", "Nantes", "Caen", "Metz", "Paris SG"),
		                     AwayTeam=c("Marseille", "Nancy", "Lille", "Lorient", "Guingamp", "Bastia", "Toulouse", "Nice", "St Etienne", "Rennes"))
		#build teams indicator for next 10 games
		next.day$home.team<-c()
		next.day$away.team<-c()
		for(k in 1:nrow(next.day))
		{
		  next.day$home.team[k]<-match(next.day$HomeTeam[k],teams)
		}
		for(k in 1:nrow(next.day)) 
		{
		  next.day$away.team[k]<-match(next.day$AwayTeam[k],teams)
		}
		#calculate predictions
		pred<-c()
		for (k in 1:nrow(next.day))
		{
		  l.x<-exp(est.final$par[2*n.teams+1] + est.final$par[2*next.day$home.team[k]-1] + est.final$par[2*next.day$away.team[k]] + est.final$par[2*n.teams+2])
		  l.y<-exp(est.final$par[2*n.teams+1] + est.final$par[2*next.day$away.team[k]-1] + est.final$par[2*next.day$home.team[k]])
		  v1<-c(0:max(dataLigue1$FTHG))
		  v2<-c(0:max(dataLigue1$FTAG))
		  prob.i<-c()
		  prob.j<-c()
		  for (i in 2:(max(dataLigue1$FTHG)+1))
		  {
		    for (j in 1:(i-1))
		    { 
		      if (j>(max(dataLigue1$FTAG)+1)) break
		      prob.j[j]<-dpois(v1[i],l.x,log=F)*dpois(v2[j],l.y,log=F)
		    }
		    prob.i[i]<-sum(prob.j, na.rm=T) 
		  }
		  home<-sum(prob.i[2:(max(dataLigue1$FTHG)+1)])
		  prob.i<-c()
		  prob.j<-c()
		  for (j in 2:(max(dataLigue1$FTAG)+1))  
		  {
		    for (i in 1:(j-1)) 
		    {
		      prob.i[i]<-dpois(v1[i],l.x,log=F)*dpois(v2[j],l.y,log=F) 
		    }
		    prob.j[j]<-sum(prob.i, na.rm=T) 
		  }
		  away<-sum(prob.j[2:(max(dataLigue1$FTAG)+1)])
		  draw<-1-home-away
		  pred<-c(pred,home,draw,away) 
		}
		predictions.finale<-matrix(pred,ncol=3,byrow=TRUE)
		dpred<-data.frame(home.team=next.day$HomeTeam, away.team=next.day$AwayTeam,
		                  home.win=predictions.finale[,1], draw=predictions.finale[,2], away.win=predictions.finale[,3])
	EOF
	end

	def old_predscript
		<<-EOF

			#import data
			setwd("/home/hubert/dataViz/dataLigue1")	
			dataLigue1<-data.frame()
			for (i in 1:(length(list.files())-1))
			{
			  oneSeason<-read.csv(list.files()[i], sep=",", header=T)[1:380,2:7]
			  dataLigue1<-rbind(dataLigue1,oneSeason)
			}
			dataLigue1<-rbind(dataLigue1,read.csv(list.files()[length(list.files())], sep=",", header=T)[1:110,2:7])
			#remove levels ""
			dataLigue1$Date<-droplevels(dataLigue1$Date)
			dataLigue1$HomeTeam<-droplevels(dataLigue1$HomeTeam)
			dataLigue1$AwayTeam<-droplevels(dataLigue1$AwayTeam)
			dataLigue1$FTR<-droplevels(dataLigue1$FTR)
			#build teams indicator
			teams<-sort(unique(dataLigue1$HomeTeam))
			dataLigue1$home.team<-c()
			dataLigue1$away.team<-c()
			for(k in 1:nrow(dataLigue1)) 
			{
			  dataLigue1$home.team[k]<-match(dataLigue1$HomeTeam[k],teams)
			}
			for(k in 1:nrow(dataLigue1))
			{
			  dataLigue1$away.team[k]<-match(dataLigue1$AwayTeam[k],teams)
			}
			#initialize estimates
			mu<-0.001
			a<-rep(0.001,length(teams))
			b<-rep(0.001,length(teams))
			tau<-0.001
			theta<-c()
			for(i in 1:length(teams))
			{
			  theta<-c(theta,a[i],b[i])
			}
			theta<-c(theta,mu,tau)
			#create loglikelyhood function
			loglik.final<- function(theta,i,j,n.teams,home.goals,away.goals)
			{
			  a.i <- theta[2*i-1]
			  b.i <- theta[2*i]
			  a.j <- theta[2*j-1]
			  b.j <- theta[2*j]
			  mu  <- theta[2*n.teams+1]
			  tau <- theta[2*n.teams+2]
			  lambda.home <- exp(mu+ a.i + b.j + tau)
			  lambda.away <- exp(mu+ a.j + b.i)
			  loglik <- sum(dpois(home.goals,lambda.home,log=T)) + sum(dpois(away.goals,lambda.away,log=T))
			  return(-loglik) 
			}
			#calculate estimates
			n.teams<-length(teams)
			est.final<-optim(c(rep(0.001,length(theta))), loglik.final, 
			                 n.teams=length(teams), i=dataLigue1$home.team, j=dataLigue1$away.team, 
			                 home.goals=dataLigue1$FTHG, away.goals=dataLigue1$FTAG, method = "L-BFGS-B")
			
			
			for(k in 1:nrow(oneSeason))
			{
			  oneSeason$home.team[k]<-match(oneSeason$HomeTeam[k],teams)
			}
			for(k in 1:nrow(oneSeason)) 
			{
			  oneSeason$away.team[k]<-match(oneSeason$AwayTeam[k],teams)
			}
			#calculate predictions
			pred<-c()
			for (k in 1:nrow(oneSeason))
			{
			  l.x<-exp(est.final$par[2*n.teams+1] + est.final$par[2*oneSeason$home.team[k]-1] + est.final$par[2*oneSeason$away.team[k]] + est.final$par[2*n.teams+2])
			  l.y<-exp(est.final$par[2*n.teams+1] + est.final$par[2*oneSeason$away.team[k]-1] + est.final$par[2*oneSeason$home.team[k]])
			  v1<-c(0:max(dataLigue1$FTHG))
			  v2<-c(0:max(dataLigue1$FTAG))
			  prob.i<-c()
			  prob.j<-c()
			  for (i in 2:(max(dataLigue1$FTHG)+1))
			  {
			    for (j in 1:(i-1))
			    { 
			      if (j>(max(dataLigue1$FTAG)+1)) break
			      prob.j[j]<-dpois(v1[i],l.x,log=F)*dpois(v2[j],l.y,log=F)
			    }
			    prob.i[i]<-sum(prob.j, na.rm=T) 
			  }
			  home<-sum(prob.i[2:(max(dataLigue1$FTHG)+1)])
			  prob.i<-c()
			  prob.j<-c()
			  for (j in 2:(max(dataLigue1$FTAG)+1))  
			  {
			    for (i in 1:(j-1)) 
			    {
			      prob.i[i]<-dpois(v1[i],l.x,log=F)*dpois(v2[j],l.y,log=F) 
			    }
			    prob.j[j]<-sum(prob.i, na.rm=T) 
			  }
			  away<-sum(prob.j[2:(max(dataLigue1$FTAG)+1)])
			  draw<-1-home-away
			  pred<-c(pred,home,draw,away) 
			}
			predictions.finale<-matrix(pred,ncol=3,byrow=TRUE)
			dpred<-data.frame(home.team=oneSeason$HomeTeam, away.team=oneSeason$AwayTeam,
			                  home.win=predictions.finale[,1], draw=predictions.finale[,2], away.win=predictions.finale[,3])
		EOF
	end
end