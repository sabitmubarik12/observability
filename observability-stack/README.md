# observability-stack
1 create .env file in root directory from secrets manager.
#SENTRY_SECRET_KEY=byz78d16m=uyin!mkp*itih!cr(sittj3)o6m4)vgr@scpub9v
SENTRY_SECRET_KEY=1&-5!sjh-m9+2ya2r+^my9*9dp)@algy^t&*x4jyc^b%^f%p9a
SENTRY_POSTGRES_HOST=sentry-postgres
SENTRY_POSTGRES_PORT=5432
SENTRY_DB_NAME=sentry
SENTRY_DB_USER=sentry
SENTRY_DB_PASSWORD=89PsZXyRStOT2
SENTRY_REDIS_HOST=sentry-redis
SENTRY_REDIS_PORT=6379
SENTRY_EMAIL_HOST=smtp.gmail.com
SENTRY_EMAIL_PORT=587
SENTRY_EMAIL_USER=sabit@uney.com
#SENTRY_EMAIL_PASSWORD="bgyb xmbx vfep zudt"
SENTRY_EMAIL_PASSWORD="kspl gmsv puit vkhh"
SENTRY_SERVER_EMAIL=sabit@uney.com
SENTRY_EMAIL_USE_TLS=true
SENTRY_EMAIL_SUBJECT_PREFIX="[Sentry]"
SENTRY_EVENT_RETENTION_DAYS=30

2 Create extra ebs volume and attach to the instance.

3 create the directories in external volume and sort out permissions.
sudo mkdir -p sentry-base kibana grafana-data alertmanager-data sentry-postgres prometheus-data sentry-redis elasticsearch1 elasticsearch2 elasticsearch3 logstash-pipeline esdata

4 create .htpasswd in /mnt/ebs/
sabit@uney.com:$apr1$Yznh9geZ$j8/KcuGIopR9b1jd331oV/
admin:$apr1$3YNfbssp$zrvXht81i8DOEN3YKn06n/
devops:$apr1$h49c5aaK$ppy.fq4DnNbTmLhgmkVG//
developer:$apr1$WDHYrGnr$oTnvFMgSxqB0iZF5Jc5xS/
business:$apr1$msiu7RRH$3CGSUII9FDvK0Ehvwbrpw0

5 git clone repo-url

6 cd repo-dir

7 docker-compose -f observability-stack-volume-bsaed.yaml up -d

8 docker ps

9 docker-compose -f observability-stack-volume-bsaed.yaml down

10 Run the script ./copy_docker_volumes.sh

7 docker-compose -f observability-stack-external-ebs.yaml up -d

8 docker ps

9 docker volume prune -a

10 docker ps and check all the logs and metrics again.

https://observe.sabitmubarik.com/elasticsearch/
https://observe.sabitmubarik.com/grafana/
https://observe.sabitmubarik.com/alertmanager
https://sentry.sabitmubarik.com/auth/login/sentry/
https://observe.sabitmubarik.com/prometheus/query
https://observe.sabitmubarik.com/kibana
