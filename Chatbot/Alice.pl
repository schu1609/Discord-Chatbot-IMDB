 use_module(library(readutil)).
 use_module(library(odbc)).

%error message
em(X) :- write("something went wrong"), X = "". %error message

dbc :- odbc_connect('imdb', _,[user(discorduser), password('sinterklaas'), alias(imdb), open(once)]).
%dbc2 :- odbc_connect('imdb', _,[user(root), password(sinterklaas), alias(imdb), open(once)]).
%dbc :- format(atom(S), 'driver=MySQL;db=~w;uid=~w;pwd=~w;port=~w;server=~w', ["imdb","leons","sinterklaas","3306","88.159.224.251"]),
    %odbc_driver_connect(S, dbcconnect, [encoding(utf8)]).

%odbc  SQL queries
%=====================================================================
checkdiscordid(W, X) :- odbc_query('imdb', 'SELECT discordId FROM Discord_accounts where discordId=~w' -[W], row(X)).
addnewuser(W,Y,Z) :- odbc_query('imdb', 'INSERT INTO imdb.discord_accounts (discordId, username) VALUES (~w, "~w")' -[W,Y], row(W,Y)).
updateuser(X,Y,Z) :- odbc_query('imdb', 'UPDATE imdb.discord_accounts SET username = "~w" WHERE discordId = ~w' -[X,Y], row(X)). 
updategenre(X,Y,Z) :- odbc_query('imdb', 'UPDATE imdb.discord_accounts SET favoriteGenre = "~w" WHERE discordId = ~w' -[X,Y], row(X)).
updatemovie(X,Y,Z) :- odbc_query('imdb', 'UPDATE imdb.discord_accounts SET favoriteMovie = "~w" WHERE discordId = ~w' -[X,Y], row(X)).
updatelanguage(X,Y) :- odbc_query('imdb', 'UPDATE imdb.discord_accounts SET speakDutch = 0 WHERE discordId = ~w' -[X], row(X)).
persfavorietefilm(W, Y, X) :- odbc_query('imdb', 'SELECT discordId FROM Discord_accounts where favoriteMovie="~w" and discordId = ~w' -[W], row(X)).
persfavorietegenre(W, Y, X) :- odbc_query('imdb', 'SELECT discordId FROM Discord_accounts where favoriteGenre="~w"and discordId = ~w' -[W], row(X)).
persaanbevelingen(W, X).
acteur(Lemma, X) :- odbc_query('imdb', 'select birthyear from imdb.name_basic where fullName="~w"' -[Lemma], row(X)).
langstefilm(X,Y) :- odbc_query('imdb', 'select primaryTitle, startYear from imdb.title_basic where titleType="movie" order by runtimeMinutes desc limit 1', row(X,Y)).
filmsspeelde(W,X) :- findall(Y, odbc_query('imdb','SELECT primaryTitle FROM title_basic, title_principals where title_basic.tconst=title_principals.tconst and
 (category="actor" or category="self") and titleType="movie" and nconst=(select nconst from imdb.name_basic where fullName="~w" limit 1)' -[W], row(Y)), X).
waardering(W,X) :- odbc_query('imdb', 'SELECT primaryTitle FROM imdb.title_basic where titleType="movie" and runtimeMinutes is not null and tconst in
(select tconst from imdb.title_ratings where averageRating between "~w" and 10) order by runtimeMinutes asc limit 1' -[W], row(X)).
hoogstescore(W,X) :- odbc_query('imdb', 'select primaryTitle from imdb.title_basic where tconst=(SELECT tconst FROM imdb.title_ratings order by averageRating desc, numVotes asc limit 1)',
 row(X)).
directoreigenfilms(W,X) :- odbc_query('imdb', 'SELECT count(primaryTitle) from imdb.title_basic, title_crew where title_basic.tconst=title_crew.tconst 
and role="D" and nconst=(select nconst from imdb.name_basic where fullName="~w" limit 1)' -[W], row(X)).
bekenstegenre(X, Y) :- odbc_query('imdb', 'SELECT genre, count(genre) as genres FROM imdb.title_genre group by genre order by genres desc limit 1', row(X,Y)).
filmsgemaakt(W,X) :- odbc_query('imdb', 'select count(tb.tconst) as movies from imdb.title_basic as tb, imdb.title_crew as tc where tb.tconst=tc.tconst
 and role="D" and titleType="movie" and nconst=(select nconst from imdb.name_basic where fullName like "%~w%" limit 1);' -[W], row(X)).
acteurinfilmnaam(W,X) :- findall(Y, odbc_query('imdb','SELECT primaryTitle FROM imdb.title_basic as tb, imdb.title_principals as tp where titleType="movie" 
and (tp.category="actor" or tp.category="actress") 
and tb.tconst=tp.tconst and primaryTitle like "%~w%" 
and tp.nconst in (select nconst from imdb.name_basic where fullName like "~w %")
and startYear between 2010 and 2021' -[W], row(Y)), X).
regisseurmetacteur(W,X) :- odbc_query('imdb', 'SELECT fullName FROM imdb.name_basic, imdb.title_principals where category=\'director\' and name_basic.nconst=title_principals.nconst 
and tconst in (select tconst from imdb.title_principals where (category="self" or category="actor") and
 nconst=(select nconst from imdb.name_basic where fullName="~w" limit 1)) 
 group by fullName order by count(fullName) desc' -[W], row(X)).
woordvaakstfilmen(W,X) :- odbc_query('imdb', 'SELECT count(tconst) as movies, startYear FROM imdb.title_basic where startYear between 1990 and 2021 and
 primaryTitle like "%~w%" and titleType="movie" group by startYear order by movies desc limit 1' -[W], row(Y,X)).
slechtstefilm(W,X) :- odbc_query('imdb', 
"SELECT fullName as movies FROM imdb.name_basic as nb, imdb.title_principals as tp where nb.nconst=tp.nconst and (category='actor' or category='actress')
 and tconst in (select tconst from imdb.title_ratings where averageRating between 1 and 3) group by fullName order by count(fullname) desc limit 1",
 row(X)).
speeltnietregiseerd(W,X) :- odbc_query('imdb', 'SELECT count(nconst) as movies FROM imdb.title_principals where 
(category="actor" or category="actress" or category="self") 
 and nconst=(select nconst from imdb.name_basic where fullName="~w" limit 1) and
 not nconst in (select nconst from imdb.title_crew where role="D")' -[W], row(X)).
personenmeerfunctie(W,X) :- findall(Y, odbc_query('imdb','SELECT distinct fullName
 from imdb.name_basic, title_crew where name_basic.nconst=title_crew.nconst
 and name_basic.nconst in (select nconst from imdb.title_principals where category="actor") limit 10', row(Y)),X).
dubbelrollen(W,X) :- odbc_query('imdb', "SELECT fullName
from imdb.name_basic as nb, title_principals as tp
where nb.nconst=tp.nconst and (category=\"actor\" or category=\"actress\")
order by (length(characters) - length(REPLACE(characters, ',', ''))+1 ) desc 
limit 1" -[W], row(X)).
% deze moet nog bekeken worden
schrijverseigenfilms(W,X) :- findall(Y, odbc_query('imdb', 'SELECT distinct name_basic.nconst, tconst, fullName from imdb.name_basic, title_crew
 where name_basic.nconst=title_crew.nconst and role=\'W\'
 and name_basic.nconst in (select nconst from imdb.title_principals where category=\'actor\')  limit 10', row(Y)),X). %ditgebruiken?
meerdereland(W,X) :- findall([Y,Z], odbc_query('imdb','select primaryTitle, max(ordering) as countries  
from imdb.title_basic, title_akas where titleType=\'movie\' and 
  title_basic.tconst=titleid group by titleid order by countries desc limit 10', row(Y,Z)),X). %misschien overzetten
% filmsspeelde(W,X) :- odbc_query('imdb', 'SELECT primaryTitle FROM imdb.title_basic, title_principals where title_basic.tconst=title_principals.tconst and
% (category="actor" or category="self") and titleType="movie" and nconst=(select nconst from imdb.name_basic where fullName="~w" limit 1)' -[W], row(X)).
%=====================================================================

%Bot questions

%=====================================================================
	category([
 	   pattern([startcommand, star(A)]),
	   template([think(dbc),think(atomics_to_string(A,'',I)),think(checkdiscordid(I, X) -> write(X) ; em(X))])
	  ]).
	category([
 	   pattern([addinguser, star(A),'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(addnewuser(X,Y,Z) 
	   -> write("") ; write("User has been added. Check database"))])
	  ]).
	category([
 	   pattern([updateuser, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(updateuser(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).	  
	category([
 	   pattern([updateusergenre, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(updategenre(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).
	category([
 	   pattern([updateusermovie, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,' ',X)),think(atomics_to_string(B,'',Y)),think(updatemovie(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).
	category([
 	   pattern([updateuserlanguage, star(A)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(updatelanguage(X,Y)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).   	  
	category([
	   pattern([can,you,star(A),'?']),
	   template(['I', 'don''t', really, know, if,'I','can', A,
	 	     but,'I''m', very, good, at, swimming])
	  ]).  
	category([
		pattern([hello]),
		template(['Hi', 'Mister', 1eons])
		]).
 category([
        pattern([star(I),"I",speak,"English", star(A)]),
		template([think(dbc),think(updatelanguage(A,X) -> format("Your language has been set to English.",[X]) ; em(X))])
	]).
	 category([
        pattern([star(I),"I",speak,"Dutch", star(A)]),
		pattern([star(I),ik,spreek,"Nederlands", star(A)]),
		template([think(dbc),think(updatelanguage(A,X) -> format("Nederlands is nu jou voorkeur taal.",[X]) ; em(X))])
	]).
	category([
        pattern([star(I),"Mijn",favoriete,film,is, star(A)]),
		template([think(dbc),think(updatemovie(A,I,X) -> format("Dat zal ik onthouden") ; em(X))])
	]).
	category([
        pattern([star(I),"mijn",favoriete,soort,is, star(A)]),
		pattern([star(I),"mijn",favoriete,genre,is, star(A)]),
		template([think(dbc),think(updategenre(A,I,Z) -> format("Dat zal ik onthouden") ; em(X))])
	]).
category([
        pattern([star(I),"Wat",is,mijn,favoriete,film,"?", star(A)]),
		template([think(dbc),think(persfavorietefilm(A,I,X) -> format("~w is jou favoriete film",[X]) ; em(X))])
	]).
category([
        pattern([star(I),'Wat',is,mijn,favoriete,soort,'?', star(A)]),
		pattern([star(I),'Wat',is,mijn,favoriete,genre,'?', star(A)]),
		template([think(dbc),think(persfavorietegenre(A,I,X) -> format("Dat is ~w.",[X]) ; em(X))])
	]).

%-------------------------------------------Dutch------------------------------------------------
category([
        pattern([star(_),'Wie',is,star(A),'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(acteur(T, X) -> format("bedoel je ~w die overleden is in ~w?",[T,X]) ; em(X))])
	]).
category([
        pattern([star(I),'Welke',film,heeft,het,langst,geduurd,om,op,te,nemen,'?']),
		template([think(dbc),think(langstefilm(X,Y) -> format("~w van ~w is op dit moment de langste film.",[X,Y]) ; em(X))])
	]).	
category([
        pattern([star(_),'In',welke,films,speelde,star(A),'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(filmsspeelde(T, X) -> format("~w speelde in ~w.",[T,X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Wat',is,de,kortste,film,met,een,waardering,van,star(A),of,hoger,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(waardering(T, X) -> format("Dat is ~w.",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Welke',film,heeft,de,hoogste,score,met,de,minste,stemmen,'?']),
		template([think(dbc),think(hoogstescore(W,X) -> format("Dat is ~w.",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Hoeveel',films,heeft,star(A),gemaakt,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(filmsgemaakt(T, X) -> format("~w heeft ~w films gemaakt",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Welke',films,zijn,er,tussen,"2010",en,nu,uitgekomen,waar,star(A),voorkomt,in,de,naam,van,de,film,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(acteurinfilmnaam(T, X) -> format("~w komt voor in ~w aantal films",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Wat',is,het,meest,voorkomende,soort,'?']),
		pattern([star(_),'Wat',is,het,meest,voorkomende,genre,'?']),
		template([think(dbc),think(bekenstegenre(X,Y) -> format("Dat is ~w. Deze komt ~w keer voor",[X,Y]) ; em(X))])
	]).	
category([
        pattern([star(_),'In',hoeveel,films,speelde,star(A),in,zijn,eigen,film,mee,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(directoreigenfilms(T, X) -> format("~w speelt in ~w van zijn eigen films",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Welke',reggiseur,heeft,de,meeste,films,met,star(A),in,de,hoofdrol,geregisseerd,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(regisseurmetacteur(T, X) -> format("~w heeft de meeste films met ~w van zijn eigen films geregisseerd",[X,T]) ; em(X))])
	]).
category([
        pattern([star(_),'In',welk,jaar,tussen,'1990',en,nu,zijn,de,meeste,films,met,de,woord,star(A),in,de,titel,geproduceerd,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(woordvaakstfilmen(T, X) -> format("~w is het jaar waar de meeste films met ~w zijn gemaakt ",[X,T]) ; em(X))])
	]).
category([
        pattern([star(_),'Welke',acteur,of,actrice,speelt,het,meest,in,de,slechtst,gewaardeerde,films,'?']),
		template([think(dbc),think(slechtstefilm(_, X) -> format("~w heeft in de meeste slechte films gespeeld",[X])  ; em(X))])
	]).
category([
        pattern([star(_),'Zijn',er,films,waarin,star(A),wel,speelde,maar,niet,regiseerde,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(speeltnietregiseerd(T, X) -> format("Ja ~w heeft in ~w gespeeld die hij of zij niet heeft geregisseerd",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Geef',een,overzicht,van,personen,die,meer,dan,"1",functie,vervulden,bij,een,film]),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(personenmeerfunctie(T, X) -> format("mensen met meedere functies zijn:~n~w",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Welke',schrijvers,spelen,in,hun,eigen,film,en,welke,films,zijn,dat,'?']),
		template(["!18Schrijvers die in hun eigen films spelen zijn:\tNaam\tFilm\tAristide Demetriade\tÎnsir\'te margarite\tJosef Sváb-Malostranský\tZpev zlata\tGunnar Helsengreen\tZirli\tChristian Schrøder\tZigøjnerblod\tWilfred Lucas\tYouth\'s Gamble\tLionel Barrymore Young\tDr. Kildare\tWallace Reid\tYou\'re Fired\tLionel Barrymore\tYou Can\'t Take It with You\tRalph Ince\tYellow Fingers\tMilton J. Fahrney\tYankee Speed"])
	]). 
category([
		pattern([star(_),'Welke',acteur,man,of,vrouw,heeft,de,langste,'filmcarrière','?']),
		template(['Dat is', 'Brahmanandam.', 'Hij heeft wel 42503 minuten lang in films gezeten'])
		]).	
category([
        pattern([star(_),'Welke',acteur,man,of,vrouw,heeft,de,meeste,dubbelrollen,'?']),
		template([think(dbc),think(dubbelrollen(T, X) -> format("~w speelt de meeste dubbelrollen",[X]) ; em(X))])
		]).
	% moet naar gekekent worden
category([
        pattern([star(_),'Welke',films,spelen,in,meer,dan,"1",land,'?']),
		template([think(dbc),think(meerdereland(T, X) -> format("films die in meerdere landen spelen zijn:~n~w",[X]) ; em(X))])
	]).
%-------------------------------------------English------------------------------------------------
	category([
 	   pattern([startcommand, star(A)]),
	   template([think(dbc),think(atomics_to_string(A,'',I)),think(checkdiscordid(I, X) -> write(X) ; em(X))])
	  ]).
	category([
 	   pattern([addinguser, star(A),'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(addnewuser(X,Y,Z) 
	   -> write("") ; write("User has been added. Check database"))])
	  ]).
	category([
 	   pattern([updateuser, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(updateuser(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).	  
	category([
 	   pattern([updateusergenre, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(atomics_to_string(B,'',Y)),think(updategenre(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).
	category([
 	   pattern([updateusermovie, star(A), 'A', star(B)]),
	   template([think(dbc),think(atomics_to_string(A,' ',X)),think(atomics_to_string(B,'',Y)),think(updatemovie(X,Y,Z)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).
	category([
 	   pattern([updateuserlanguage, star(A)]),
	   template([think(dbc),think(atomics_to_string(A,'',X)),think(updatelanguage(X,Y)
	   -> write("") ; write("User has been updated. Check database"))])
	  ]).   	  
	category([
	   pattern([can,you,star(A),'?']),
	   template(['I', 'don''t', really, know, if,'I','can', A,
	 	     but,'I''m', very, good, at, swimming])
	  ]).  
	category([
		pattern([hello]),
		template(['Hi', 'Mister', user])
		]).
 category([
        pattern([star(I),"I",speak,"English", star(A)]),
		template([think(dbc),think(updatelanguage(A,X) -> format("Language has been updated.",[X]) ; em(X))])
	]).
	 category([
        pattern([star(I),"I",speak,"Dutch", star(A)]),
		pattern([star(I),ik,spreek,"Nederlands", star(A)]),
		template([think(dbc),think(updatelanguage(A,X) -> format("Taal is nu aangepast.",[X]) ; em(X))])
	]).
	category([
        pattern([star(I),"My",favorite,movie,is, star(A)]),
		template([think(dbc),think(updatemovie(A,I,X) -> format("I will remember that") ; em(X))])
	]).
	category([
		pattern([star(I),"My",favorite,genre,is, star(A)]),
		template([think(dbc),think(updategenre(A,I,Z) -> format("I will remember that") ; em(X))])
	]).
category([
        pattern([star(I),'What',is,my,favorite,movie,"?", star(A)]),
		template([think(dbc),think(persfavorietefilm(A,I,X) -> format("~w is your favorite movie",[X]) ; em(X))])
	]).
category([
		pattern([star(I),'What',is,my,favorite,genre,'?', star(A)]),
		template([think(dbc),think(persfavorietegenre(A,I,X) -> format("Your favorite genre is ~w.",[X]) ; em(X))])
	]).
category([
        pattern([star(_),'Who',is,star(A),'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(acteur(T, X) -> format("do you mean ~w who died in ~w?",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Which',movie,took,the,longest,to,film,'?']),
		template([think(dbc),think(langstefilm(X,Y) -> format("~w with ~w minutes is at this moment the longest movie.",[X,Y]) ; em(X))])
	]).	
category([
        pattern([star(_),'In',which,movie,played,star(A),'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(filmsspeelde(T, X) -> format("~w played in ~w.",[T,X]) ; em(X))])
	]).	
category([
        pattern([star(_),'What',is,the,shortest,movie,with,a,rating,of,star(A),or,higher,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(waardering(T, X) -> format("That is ~w.",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Which',movie,has,the,highest,score,with,the,least,amount,of,votes,'?']),
		template([think(dbc),think(hoogstescore(W,X) -> format("That is ~w.",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'How',many,movies,did,star(A),create,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(filmsgemaakt(T, X) -> format("~w has made ~w movies",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Which',movies,between,"2010",and,now,has,the,word,star(A),in,their,movie,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(acteurinfilmnaam(T, X) -> format("~w acts in ~w approximately",[T,X]) ; em(X))])
	]).
category([
		pattern([star(_),'What',is,the,most,common,genre,'?']),
		template([think(dbc),think(bekenstegenre(X,Y) -> format("That is ~w. this genre is seen ~w times",[X,Y]) ; em(X))])
	]).	
category([
        pattern([star(_),'In',how,many,movies,did,star(A),in,their,own,created,movie,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(directoreigenfilms(T, X) -> format("~w plays in ~w of his own directed movies",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Which',director,heeft,de,meeste,films,met,star(A),in,de,hoofdrol,geregisseerd,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(regisseurmetacteur(T, X) -> format("~w has directed the most movies with ~w",[X,T]) ; em(X))])
	]).
category([
        pattern([star(_),'In',which,year,between,'1990',and,where,the,most,movies,produced,with,the,word,star(A),in,there,title,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(woordvaakstfilmen(T, X) -> format("~w is the year where the most movies with ~w are made",[X,T]) ; em(X))])
	]).
category([
        pattern([star(_),'Which',actor,or,actrice,plays,in,the,the,worst,rated,movies,'?']),
		template([think(dbc),think(slechtstefilm(_, X) -> format("~w has played in the worst movie",[X])  ; em(X))])
	]).
category([
        pattern([star(_),'Are',there,movies,where,star(A),plays,in,but,does,not,produce,'?']),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(speeltnietregiseerd(T, X) -> format("Yes ~w has played in ~w which he did not direct",[T,X]) ; em(X))])
	]).
category([
        pattern([star(_),'Give',an,overview,of,persons,who,fulfilled,more,than,"1",function,at,a,movie]),
		template([think(dbc),think(atomics_to_string(A,' ',T)),think(personenmeerfunctie(T, X) -> format("People with more then 1 function are:~n~w",[X]) ; em(X))])
	]).	
category([
        pattern([star(_),'Which',writers,play,in,their,own,movie,and,what,are,those,movies,'?']),
		template(["!18Writers who play in their own movie are:\t","Name\tMovie\t","Aristide Demetriade\tÎnsir\'te margarite\tJosef Sváb-Malostranský\tZpev zlata\tGunnar Helsengreen\tZirli\tChristian Schrøder\tZigøjnerblod\tWilfred Lucas\tYouth\'s Gamble\tLionel Barrymore Young\tDr. Kildare\tWallace Reid\tYou\'re Fired\tLionel Barrymore\tYou Can\'t Take It with You\tRalph Ince\tYellow Fingers\tMilton J. Fahrney\tYankee Speed"])
	]). 
category([
		pattern([star(_),'Which',actor,or,actrice,got,the,longest,'filmcarrière','?']),
		template(['That is', 'Brahmanandam.', 'He got a runtime in movies for about 42503 minutes.'])
		]).	
category([
        pattern([star(_),'Which',actor,or,actrice,got,the,most,different,rolls,in,a,movie,'?']),
		template([think(dbc),think(dubbelrollen(T, X) -> format("~w played the most double rolls",[X]) ; em(X))])
		]).
category([
        pattern([star(_),'Which',movies,play,in,more,then,"1",country,'?']),
		template([think(dbc),think(meerdereland(T, X) -> format("Movies that are played in different countries are:~n~w",[X]) ; em(X))])
	]).

%Functionality
%=======================================================================

:- use_module(library(lists),[member/2,nth0/3,append/3]).
:- use_module(library(random),[random/3]).

:- dynamic alice_var/2.

%=======================================================================
% loop.
% loop(+Context).
% loop/0 is the top predicate.
% loop/1 uses the argument  to keep track of the context.

loop:-
	loop([hello]).

loop(Context):-
	interact_once(Context,NewContext),!,   % Try once only
	loop(NewContext).

%
%=======================================================================

%=======================================================================
% interact_once(+Context,-NewContext)
% Do one interaction

interact_once(Context,NewContext):-
	read_atomics(L),
	find_and_reply(L,Context,NewContext).

%
%=======================================================================

%=======================================================================
% find_and_reply(+Input,+Context,-NewContext)
% Find a rule that matches the input and produce the response

find_and_reply(Input,Context,NewContext):-
	% Category with "that"
	category(C),
	member(that(TH),C),
	tokenise(TH,THTokens),
	tokenise(Context,CTokens),
	input_match(THTokens,CTokens),
	member(pattern(P),C),
	tokenise(P,PTokens),
	input_match(PTokens,Input),
	member(template(T),C),
	generate_response(T,Context,NewContext),nl.

find_and_reply(Input,Context,NewContext):-
	% Category without "that"
	category(C),
	\+ member(that(_),C), % Added 3/10/2002
	member(pattern(P),C),
	tokenise(P,PTokens),
	input_match(PTokens,Input),
	member(template(T),C),
	generate_response(T,Context,NewContext),nl.

%=======================================================================
% find_and_reply(+Input,+Context,-NewContext)
% Find a rule that matches the input and produce the response

find_and_reply_srai(Input,Context,NewContext):-
	% Category with "that"
	category(C),
	member(that(TH),C),
	tokenise(TH,THTokens),
	tokenise(Context,CTokens),
	input_match(THTokens,CTokens),
	member(pattern(P),C),
	tokenise(P,PTokens),
	tokenise(Input,ITokens),
	input_match(PTokens,ITokens),
	member(template(T),C),
	generate_response(T,Context,NewContext).

find_and_reply_srai(Input,Context,NewContext):-
	% Category without "that"
	category(C),
	\+ member(that(_),C), % Added 3/10/2002
	member(pattern(P),C),
	tokenise(P,PTokens),
	tokenise(Input,ITokens),
	input_match(PTokens,ITokens),
	member(template(T),C),
	generate_response(T,Context,NewContext).

%
%========================================================================

%========================================================================
% input_match(+Pattern,+Input)
% Succeed if the input line matches the pattern. All variables in the
% pattern result instantiated in the process.

input_match([],[]).

input_match([H|T],[H|T2]):-
	input_match(T,T2).

input_match([star([])|T],Input_Line):-
	input_match(T,Input_Line).

input_match([star([H|TStar])|T],[H|T2]):-
	input_match([star(TStar)|T],T2).

input_match([syntax(SynCat,Match)|T],Input_Line):-
	PredCall =.. [SynCat,Input_Line,Rest],
	call(PredCall),                 % Call to the grammar rules
	append(Match,Rest,Input_Line),
	input_match(T,Rest).

input_match([syntax(SynCat,Match,Features)|T],Input_Line):-
	append([SynCat|Features],[Input_Line,Rest],PredCallList),
	PredCall =.. PredCallList,
	call(PredCall),                 % Call to the grammar rules
	append(Match,Rest,Input_Line),
	input_match(T,Rest).

%
%=======================================================================

%=======================================================================
% generate_response(+Template,+Context,-Response)
% Output the response that corresponds to the template and the given
% context. The output argument Response contains the generated
% response tokenised so that it can be used as the context of the
% next interaction.

generate_response([],_,[]).

generate_response([think(Commands)|T],Context,FinalResponse):-
	!,
	% "think" element
	call(Commands),
	generate_response(T,Context,FinalResponse).

generate_response([srai(SRAIList)|T],Context,FinalResponse):-
	!,
	% "srai" element
	flatten_list(SRAIList,FlattenedList),
	find_and_reply_srai(FlattenedList,Context,SRAIResponse),
	generate_response(T,Context,TResponse),
	append(SRAIResponse,TResponse,FinalResponse).

generate_response([random(RandomList)|T],Context,FinalResponse):-
	!,
	% "random" element
	list_length(RandomList,Length),
	random(0,Length,Random),
	nth0(Random,RandomList,ChosenList),
	generate_response(ChosenList,Context,ListResponse),
	generate_response(T,Context,TResponse),
	append(ListResponse,TResponse,FinalResponse).

generate_response([H|T],Context,FinalResponse):-
	H = [_|_],
	!,
	% A list; we need to flatten out all lists
	generate_response(H,Context,HResponse),
	generate_response(T,Context,TResponse),
	append(HResponse,TResponse,FinalResponse).

generate_response([H|T],Context,[H|TResponse]):-
	% Default rule
	write(H),
	write(' '),
	generate_response(T,Context,TResponse).

%
%======================================================================

%======================================================================
% flatten_list(+List,-Flattened)
% Utility predicate that flattens out a list

flatten_list([],[]).
flatten_list([[]|T],Flat):-
	flatten_list(T,Flat).
flatten_list([H|T],Flat):-
	H = [_|_],
	flatten_list(H,FlattenedHead),
	flatten_list(T,FlattenedTail),
	append(FlattenedHead,FlattenedTail,Flat).
flatten_list([H|T],[H|FlatTail]):-
	\+ H = [],
	\+ H = [_|_],
	flatten_list(T,FlatTail).

%
%======================================================================

%======================================================================
% list_length(+List,-N)
% Utility predicate that returns the length of the list

list_length([],0).

list_length([_|T],L):-
	list_length(T,L2),
	L is L2 + 1.

%
%======================================================================

%======================================================================
% get_var(+VarName,?Value)
% set_var(+VarName,+Value)
% Utility predicates to get the value of a Bot variable or set the
% variable

get_var(VarName,Value):-
	alice_var(VarName,Value).

get_var(VarName,[]):-
	\+ alice_var(VarName,_).

set_var(VarName,Value):-
	retractall(alice_var(VarName,_)),
	tokenise(Value,Tokens),
	asserta(alice_var(VarName,Tokens)).

%
%=======================================================================

%=======================================================================
% tokenise(+Atom,-List)
% Convert an atom representing text into a list of tokens. This
% predicate makes heavy use of the definitions in readatom.pl (below)

tokenise([],[]):-
	!.
tokenise([star(A)|T],[star(A)|Tokenised]):-
	!,
	tokenise(T,Tokenised).
tokenise([syntax(A,B)|T],[syntax(A,B)|Tokenised]):-
	!,
	tokenise(T,Tokenised).
tokenise([Atom|T],Tokens):-
	atomic(Atom),
	!,
	tokenise_atom(Atom,AtomTokens),
	tokenise(T,TTokens),
	append(AtomTokens,TTokens,Tokens).
tokenise(Input,Input):-
	write('WARNING: Unable to tokenise '),
	writeq(Input).

tokenise_atom(Atom,List):-
	name(Atom,String),
	tokenise_string(String,List).

% tokenise_string(String,Atomics)
%  Counterpart of read_atomics/1 below

tokenise_string([],Atomics):-
	complete_string([],nil,end,Atomics).

tokenise_string([C|Tail],Atomics):-
	char_type(C,Type,Char),
	complete_string(Tail,Char,Type,Atomics).

% complete_string(+Buffer,+FirstC,+FirstT,-Atomics)
%   Counterpart of complete_line/3 below

complete_string(_,_,end,[]) :- !.                  % stop at end

complete_string(B,_,blank,Atomics) :-              % skip blanks
   !,
   tokenise_string(B,Atomics).

complete_string(B,FirstC,special,[A|Atomics]) :-   % special char
   !,
   name(A,[FirstC]),
   tokenise_string(B,Atomics).

complete_string(B,FirstC,alpha,[A|Atomics]) :-     % begin word
   complete_string_word(B,BOut,FirstC,alpha,Word,NextC,NextT),
   name(A,Word),  % may not handle numbers correctly - see text
   complete_string(BOut,NextC,NextT,Atomics).

% complete_string_word(+BufferIn,-BufferOut,+FirstC,+FirstT,
%                      -List,-FollC,-FollT)
% counterpart of complete_word/5 below

complete_string_word([],[],FirstC,alpha,[FirstC|List],FollC,FollT) :-
   !,
   complete_string_word([],[],nil,end,List,FollC,FollT).

complete_string_word([C|BTail],BOut,FirstC,alpha,[FirstC|List],FollC,FollT) :-
   !,
   char_type(C,NextT,NextC),
   complete_string_word(BTail,BOut,NextC,NextT,List,FollC,FollT).

complete_string_word(B,B,FirstC,FirstT,[],FirstC,FirstT).
   % where FirstT is not alpha

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File READATOM.PL
% Michael A. Covington
% Natural Language Processing for Prolog Programmers
% (Prentice-Hall)
% Appendix B

% Version of read_atomics/1 for most Prologs.  See text.


% read_atomics(-Atomics)
%  Reads a line of text, breaking it into a
%  list of atomic terms: [this,is,an,example].

read_atomics(Atomics) :-
   read_char(FirstC,FirstT),
   complete_line(FirstC,FirstT,Atomics).


% read_char(-Char,-Type)
%  Reads a character and runs it through char_type/3.

read_char(Char,Type) :-
   get0(C),
   char_type(C,Type,Char).


% complete_line(+FirstC,+FirstT,-Atomics)
%  Given FirstC (the first character) and FirstT (its type), reads
%  and tokenizes the rest of the line into atoms and numbers.

complete_line(_,end,[]) :- !.                  % stop at end

complete_line(_,blank,Atomics) :-              % skip blanks
   !,
   read_atomics(Atomics).

complete_line(FirstC,special,[A|Atomics]) :-   % special char
   !,
   name(A,[FirstC]),
   read_atomics(Atomics).

complete_line(FirstC,alpha,[A|Atomics]) :-     % begin word
   complete_word(FirstC,alpha,Word,NextC,NextT),
   name(A,Word),  % may not handle numbers correctly - see text
   complete_line(NextC,NextT,Atomics).


% complete_word(+FirstC,+FirstT,-List,-FollC,-FollT)
%  Given FirstC (the first character) and FirstT (its type),
%  reads the rest of a word, putting its characters into List.

complete_word(FirstC,alpha,[FirstC|List],FollC,FollT) :-
   !,
   read_char(NextC,NextT),
   complete_word(NextC,NextT,List,FollC,FollT).

complete_word(FirstC,FirstT,[],FirstC,FirstT).
   % where FirstT is not alpha


% char_type(+Code,?Type,-NewCode)
%  Given an ASCII code, classifies the character as
%  'end' (of line/file), 'blank', 'alpha'(numeric), or 'special',
%  and changes it to a potentially different character (NewCode).

char_type(10,end,10) :- !.         % UNIX end of line mark
char_type(13,end,13) :- !.         % DOS end of line mark
char_type(-1,end,-1) :- !.         % get0 end of file code

char_type(Code,blank,32) :-        % blanks, other ctrl codes
  Code =< 32,
  !.

char_type(Code,alpha,Code) :-      % digits
  48 =< Code, Code =< 57,
  !.

char_type(Code,alpha,Code) :-      % lower-case letters

  97 =< Code, Code =< 122,
  !.

char_type(Code,alpha,NewCode) :-   % upper-case letters
  65 =< Code, Code =< 90,
  !,
  NewCode is Code + 32.            %  (translate to lower case)

char_type(Code,special,Code).      % all others

%--End-------------------------------------------------------------------
