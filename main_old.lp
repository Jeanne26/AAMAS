% Context  
context(mission;low_water;storm_front).
act(hike;ford;call_heli;carry;secure_camp).
event(at_river;across;heli_here;evacuated;siren;sheltered).

step(0..1).
beliefBase(env;ag).


% CAUSAL THEORY 

chead(c1,at_river).    body(c1,hike).
chead(c2,heli_here).   body(c2,call_heli).
chead(c3,siren).       body(c3,storm_front).
chead(c4,sheltered).   body(c4,secure_camp).
chead(c5,across).      body(c5,ford). body(c5,low_water). body(c5,at_river).
chead(c6,evacuated).   body(c6,carry). body(c6,across).
chead(c7,evacuated).   body(c7,carry). body(c7,heli_here).


% DECISION THEORY 

choice(gw;gh;gf;ge;gs).

dhead(d1,gw).   body(d1,mission).
dhead(d2,gh).   body(d2,mission).
dhead(d3,ge).   body(d3,across).
dhead(d4,ge).   body(d4,heli_here).
dhead(d5,gs).   body(d5,siren).
dhead(d6,gf).   body(d6,low_water). body(d6,at_river).

offers(gw,hike).        cmin(gw,1). cmax(gw,1).
offers(gh,call_heli).   cmin(gh,0). cmax(gh,1).
offers(gf,ford).        cmin(gf,0). cmax(gf,1).
offers(ge,carry).       cmin(ge,1). cmax(ge,1).
offers(gs,secure_camp). cmin(gs,1). cmax(gs,1).


% SCENARIO 

believe(S,env,mission) :- step(S).
believe(S,env,storm_front):- step(S).


believe(0,ag,mission).
believe(0,ag,low_water).


decision(0,hike).
decision(0,ford).
decision(0,carry).


% CAUSAL LAYER 

satisfaction(S,B,A) :- decision(S,A), beliefBase(B).       % action
satisfaction(S,B,X) :- believe(S,B,X).                     % context
satisfaction(S,B,E) :- holds(S,B,E).                       % event

fails(S,B,R) :- step(S), beliefBase(B), body(R,X), not satisfaction(S,B,X).
holds(S,B,E) :- chead(R,E), step(S), beliefBase(B), not fails(S,B,R).


% DECISION LAYER

trig(S,B,G) :- dhead(R,G), step(S), beliefBase(B), not fails(S,B,R).

offered(S,B,A) :- trig(S,B,G), offers(G,A).

card(S,B,G,N) :- trig(S,B,G), N = #count{A:offers(G,A),decision(S,A)}.

% Violations
viol(S,B,coverage(A)) :- decision(S,A), beliefBase(B), not offered(S,B,A).
viol(S,B,bound(G))    :- card(S,B,G,N), cmin(G,M), N < M.
viol(S,B,bound(G))    :- card(S,B,G,N), cmax(G,M), N > M.

inadm(S,B) :- viol(S,B,_).
adm(S,B)   :- step(S), beliefBase(B), not inadm(S,B).





% DECISION FAILURE 

contradicted(S) :- adm(S,ag), inadm(S,env).
contradicted(S) :- inadm(S,ag), adm(S,env).

missed(S,G)    :- trig(S,env,G), not trig(S,ag,G), step(S).
incorrect(S,G) :- trig(S,ag,G),  not trig(S,env,G), step(S).

wabs(S,G) :- missed(S,G), card(S,env,G,N), cmin(G,M), N < M.
wabs(S,G) :- missed(S,G), card(S,env,G,N), cmax(G,M), N > M.

wma(S,G) :- incorrect(S,G), offers(G,A), decision(S,A), not offered(S,env,A).

witness(S,G) :- wabs(S,G).
witness(S,G) :- wma(S,G).

forced(G) :- cmin(G,M), M > 0.
capped(G) :- cmax(G,M), M < #count{A:offers(G,A)}.


% OBSERVABLE FAILURE 

obs(pos,siren).
obs(pos,at_river).
obs(pos,across).
obs(neg,across).
obs(pos,heli_here).

:- obs(pos,K), context(K), believe(S,ag,K), not believe(S,env,K).
:- obs(pos,K), context(K), not believe(S,ag,K), believe(S,env,K).

% Condition discriminante observable d'un temoin d'absence :
% une regle du choix, vraie cote env, dont tous les litteraux non-action sont dans Obs
% unobsbody(R) :- body(R,Sg,X), not act(X), not obs(Sg,X).
% wabs_det(S,G) :- wabs(S,G), dhead(R,G), not fails(S,env,R), not unobsbody(R).

% % Temoin d'anticipation erronee detecte : pour chaque regle de G vraie cote agent,
% % un litteral faux cote env dont la negation est dans Obs
% neg_obs(S,R) :- body(R,Sg,X), opp(Sg,Sg2), obs(Sg2,X), not act(X),
%                 step(S), not ltrue(S,env,Sg,X).
% wma_bad(S,G) :- wma(S,G), dhead(R,G), not fails(S,ag,R), not neg_obs(S,R).
% wma_det(S,G) :- wma(S,G), not wma_bad(S,G).

% wdet(S,G) :- wabs_det(S,G).
% wdet(S,G) :- wma_det(S,G).

% % Echec silencieux : decision contredite sans aucun temoin detectable
% % (verification locale d'adequation pour la decision courante, cf. Def. 5.2)
% silent_failure(S) :- contradicted(S), not wdet(S,_), step(S).

#show contradicted/1.
#show missed/2.
#show incorrect/2.
#show wabs/2.
#show wma/2.
#show believe/3.
