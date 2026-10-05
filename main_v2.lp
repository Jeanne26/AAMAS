% =====================================================================
% Acting on False Beliefs -- version main.lp complétée
% (mêmes conventions que ton main.lp : body(R,X) sans signe,
%  decision/3, satisfaction/3, card/4, beliefBase/1)
% =====================================================================

% VOCABULARY
context(mission;low_water;storm_front).
act(hike;ford;call_heli;carry;secure_camp).
event(at_river;across;heli_here;evacuated;siren;sheltered).

step(0..1).
rstep(0,1).                 % revision de l'étape 0 vers l'étape 1
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
believe(S,env,mission)     :- step(S).
believe(S,env,storm_front) :- step(S).

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

viol(S,B,coverage(A)) :- decision(S,A), beliefBase(B), not offered(S,B,A).
viol(S,B,bound(G))    :- card(S,B,G,N), cmin(G,M), N < M.
viol(S,B,bound(G))    :- card(S,B,G,N), cmax(G,M), N > M.

inadm(S,B) :- viol(S,B,_).
adm(S,B)   :- step(S), beliefBase(B), not inadm(S,B).

:- not adm(0,ag).


% DECISION FAILURE 
contradicted(S) :- adm(S,ag), inadm(S,env).

missed(S,G)    :- trig(S,env,G), not trig(S,ag,G), step(S).
incorrect(S,G) :- trig(S,ag,G),  not trig(S,env,G), step(S).

wviol(S,G) :- missed(S,G), card(S,env,G,N), cmin(G,M), N < M.
wviol(S,G) :- missed(S,G), card(S,env,G,N), cmax(G,M), N > M.

wma(S,G) :- incorrect(S,G), offers(G,A), decision(S,A), not offered(S,env,A).

witness(S,G) :- wviol(S,G).
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

%Absence witnesses
unobsbody(R) :- body(R,X), not act(X), not obs(pos,X).

wviol_det(S,G) :- wviol(S,G), dhead(R,G), not fails(S,env,R), not unobsbody(R).

missed_det(S,G) :- missed(S,G), not wviol(S,G), dhead(R,G), not fails(S,env,R), not unobsbody(R).

%Mistaken anticipation witness
neg_obs(S,R) :- body(R,X), obs(neg,X), not act(X), step(S),
                not satisfaction(S,env,X).
bad(S,G)     :- incorrect(S,G), dhead(R,G), not fails(S,ag,R), not neg_obs(S,R).
wma_det(S,G) :- wma(S,G), not bad(S,G).


wdet(S,G) :- wviol_det(S,G).
wdet(S,G) :- wma_det(S,G).

% case Sec. 5.2
case(S,G,viol_observable)         :- wwiol_det(S,G).
case(S,G,opportunity_noticed)    :- missed_det(S,G).
case(S,G,opportunity_missed)     :- missed(S,G), not wviol(S,G), not missed_det(S,G).
case(S,G,modelling_contradiction):- wviol(S,G), not wviol_det(S,G).

case(S,G,ma_observable)          :- wma_det(S,G).
case(S,G,ma_unobservable)        :- wma(S,G), bad(S,G).
case(S,G,prediction_falsified)   :- incorrect(S,G), not wma(S,G), not bad(S,G).
case(S,G,silent_misprediction)   :- incorrect(S,G), not wma(S,G), bad(S,G).

%local adequation test
silent_failure(S) :- contradicted(S), not wdet(S,_), step(S).


% TEMPORAL ORDER 
tracked(X) :- act(X).
tracked(X) :- event(X).

lt0(X,E) :- chead(R,E), body(R,X), tracked(X).
lt0(X,A) :- dhead(R,G), body(R,X), tracked(X), offers(G,A).

eqv(X,Y) :- offers(G,X), offers(G,Y).
eqv(X,Z) :- eqv(X,Y), eqv(Y,Z).

lt(X,Y) :- lt0(X,Y).
lt(X,Z) :- lt(X,Y), lt(Y,Z).
lt(X,Z) :- lt(X,Y), eqv(Y,Z).
lt(Z,Y) :- lt(X,Y), eqv(X,Z).

incoherent :- lt(X,X).
:- incoherent.


% ALERTS 
cause(S,pos,E) :- holds(S,env,E), not holds(S,ag,E), obs(pos,E).
cause(S,neg,E) :- holds(S,ag,E), not holds(S,env,E), obs(neg,E).

dominated(S,K,E) :- cause(S,K,E), cause(S,_,E2), lt(E2,E).
alert(S,K,E)     :- cause(S,K,E), not dominated(S,K,E).

pres(S,A) :- alert(S,_,E), lt(A,E), act(A).


% REVISION (Def. 6.10 -- 6.13)
% Sans alerte : pas de révision (B^1 = B^0, D^1 = D^0).
% Avec alerte : (B^1, D^1) devinés, un answer set = un élément de Rev.
rev(S) :- rstep(S,_), alert(S,_,_).

believe(T,ag,K)  :- rstep(S,T), believe(S,ag,K), not rev(S).
decision(T,A)    :- rstep(S,T), decision(S,A),   not rev(S).

{ believe(T,ag,K) : context(K) } :- rstep(S,T), rev(S).
{ decision(T,A)   : act(A)     } :- rstep(S,T), rev(S).

% critère (a) : la révision rend compte des alertes côté agent
:- rstep(S,T), alert(S,pos,E), not holds(T,ag,E).
:- rstep(S,T), alert(S,neg,E),     holds(T,ag,E).

% critère (b) : préservation du passé
:- rstep(S,T), pres(S,A), decision(S,A), not decision(T,A).
:- rstep(S,T), pres(S,A), decision(T,A), not decision(S,A).

% admissibilité relative à P^S (Def. 6.12)
notsub(S,G) :- rstep(S,_), choice(G), offers(G,A), not pres(S,A).
rviol(T,coverage(A)) :- rstep(S,T), decision(T,A), not pres(S,A), not offered(T,ag,A).
rviol(T,bound(G))    :- rstep(S,T), card(T,ag,G,N), cmin(G,M), N < M, notsub(S,G).
rviol(T,bound(G))    :- rstep(S,T), card(T,ag,G,N), cmax(G,M), N > M, notsub(S,G).
:- rviol(_,_).


% EVALUATION (Sec. 7.3)
v(evacuated,1).
v(sheltered,1).

totalUti(S,B,T) :- step(S), beliefBase(B), T = #sum{V,E : holds(S,B,E), v(E,V)}.

expectations_absolve(S) :- totalUti(S,ag,Te), totalUti(S,env,Tr), Te > Tr.

excusable(S,G)               :- witness(S,G), not wdet(S,G), not wviol(S,G).
revision_required(S,G)       :- witness(S,G), wdet(S,G).
culpable_if_kept(S,G)        :- wviol(S,G), wdet(S,G).
modelling_contradiction(S,G) :- wviol(S,G), not wviol_det(S,G).


#show adm/2.
#show forced/1.
#show capped/1.
#show contradicted/1.
#show missed/2.
#show incorrect/2.
#show wviol/2.
#show wma/2.
#show case/3.
#show silent_failure/1.
#show holds/3.
#show cause/3.
#show alert/3.
#show pres/2.
#show believe/3.
#show decision/2.
#show totalUti/3.
#show expectations_absolve/1.
#show excusable/2.
#show revision_required/2.
#show culpable_if_kept/2.
#show modelling_contradiction/2.
