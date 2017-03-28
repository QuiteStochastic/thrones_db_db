FROM ubuntu:16.04
RUN mkdir /code
WORKDIR /code

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install apt-utils

RUN apt-get -y update && \
    apt-get -y install sudo

RUN apt-get -y install postgresql
RUN update-rc.d postgresql defaults


ADD ./db/migration/ /code/data

RUN service postgresql start && \
	sudo -u postgres psql -c "CREATE USER thrones_db_user PASSWORD 'kingsguard';" && \
	sudo -u postgres psql -c "CREATE DATABASE thronesdb_db WITH OWNER = thrones_db_user CONNECTION LIMIT = -1;" && \
	sudo -u postgres psql -d thronesdb_db -c "CREATE SCHEMA thrones_db_schema AUTHORIZATION thrones_db_user;" && \
	sudo -u postgres psql -d thronesdb_db -c "ALTER ROLE thrones_db_user SET search_path = thrones_db_schema;" && \
	#export PGPASSWORD=kingsguard && \
	#sudo touch /code/.pgpass && \
	#sudo echo "*:*:*:thrones_db_user:kingsguard" > /code/.pgpass && \
	#export PGPASSFILE=/code/.pgpass && \
	#echo "$PGPASSFILE" && \
	#echo "$PGPASSWORD" && \

	sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.episode ( episodeId serial PRIMARY KEY NOT NULL, name character varying(500), season int,episodeNumber int, description text);" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.episode OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.episode FROM '/code/data/episode.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.character ( characterId serial PRIMARY KEY NOT NULL, firstName character varying(255),lastName character varying(255),alias character varying(255),gender character varying(255),religion character varying(255), status character varying(255), description text);" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.character OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.character FROM '/code/data/character.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.location (locationId serial PRIMARY KEY NOT NULL, name character varying(255),locationType character varying(255), description text, superiorLocationId integer REFERENCES thrones_db_schema.location(locationId));" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.location OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.location FROM '/code/data/location.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.event (eventId serial PRIMARY KEY NOT NULL, name character varying(255),eventType character varying(255), description text, locationId integer REFERENCES thrones_db_schema.location(locationId), episodeId integer REFERENCES thrones_db_schema.episode(episodeId) );" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.event OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.event FROM '/code/data/event.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.organization (organizationId serial PRIMARY KEY NOT NULL, name character varying(255), organizationType character varying(255), description text,seatLocationId integer REFERENCES thrones_db_schema.location(locationId),leaderCharacterId integer REFERENCES thrones_db_schema.character(characterId) );" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.organization OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.organization FROM '/code/data/organization.csv' delimiter ',' csv;" && \




    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.member (memberId serial PRIMARY KEY NOT NULL,  rank character varying(255),  status character varying(255),  active boolean, characterId integer REFERENCES thrones_db_schema.character(characterId), organizationId integer REFERENCES thrones_db_schema.organization(organizationId)  );" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.member OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.member FROM '/code/data/member.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.participant (characterId integer REFERENCES thrones_db_schema.character(characterId),eventId integer REFERENCES thrones_db_schema.event(eventId));" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.participant OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.participant FROM '/code/data/participant.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.party (organizationId integer REFERENCES thrones_db_schema.organization(organizationId),eventId integer REFERENCES thrones_db_schema.event(eventId));" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.party OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.party FROM '/code/data/party.csv' delimiter ',' csv;" && \

    sudo -u postgres psql -d thronesdb_db -c "CREATE TABLE thrones_db_schema.visitor (characterId integer REFERENCES thrones_db_schema.character(characterId),locationId integer REFERENCES thrones_db_schema.location(locationId));" && \
    sudo -u postgres psql -d thronesdb_db -c "ALTER TABLE thrones_db_schema.visitor OWNER TO thrones_db_user;" && \
    sudo -u postgres psql -d thronesdb_db -c "COPY thrones_db_schema.visitor FROM '/code/data/visitor.csv' delimiter ',' csv;" && \

    rm -rf /code/data

	#sudo -u postgres psql -d thronesdb_db -c "insert into thrones_db_schema.episode (episodeId, name, season, episodeNumber, description) values (1,'test1-1',1,1,'describe1-1'), (2,'test1-2',1,2,'describe1-2'), (3,'test2-1',2,11,'describe2-1'), (4,'test2-2',2,12,'describe2-2');"


EXPOSE 5432

CMD service postgresql start && tail -f /var/log/postgresql/postgresql-9.5-main.log
