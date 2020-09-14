:- module(validate_schema,[
              invalidate_schema/1,

              class/2,
              immediate_class/2,
              restriction/2,
              class_or_restriction/2,
              sub_class_of/3,
              union_of/3,
              intersection_of/3,
              sub_class_strict/3,
              disjoint_union_of/3,
              label/3,
              comment/3,
              subsumption_of/3,
              strict_subsumption_of/3,
              complement_of/3,
              system_tag/3,
              document/2,

              union_of_list/3,
              intersection_of_list/3,
              disjoint_union_of_list/3,
              one_of_list/3,

              datatype_property/2,
              object_property/2,
              annotation_property/2,
              property/2,
              sub_property_of/3,
              subsumption_properties_of/3,
              range/3,
              domain/3,
              any_range/3,
              any_domain/3,
              most_specific_domain/3,
              most_specific_range/3,
              collect/4,
              functional_property/2,
              inverse_functional_property/2,
              restriction_on_property/3,
              datatype_subsumption_of/3,
              basetype_subsumption_of/2,
              custom_datatype/2,
              datatype/2,
              strict_subsumption_property_of/3,
              orphan_property/4,
              rdf_meta_property/1,
              rdfs_property/1,
              % SC == Schema Constraints
              % constraints must be pred/2

              % REQUIRED Best Practice
              class_cycle_SC/2,               % Best Practice
              property_cycle_SC/2,            % Best Practice

              % Best practice
              no_immediate_domain_SC/2,
              no_immediate_range_SC/2,         % Best Practice
              % schema_blank_node_SC/2,
              not_unique_class_label_SC/2,      % Best Practice
              not_unique_class_SC/2,
              not_unique_property_SC/2,        % Best Practice
              no_immediate_class_SC/2,
              annotation_overload_SC/2,
              property_type_overload_SC/2,

              % OWL DL (Constraint)
              orphan_class_SC/2,              % OWL
              orphan_property_SC/2,           % OWL
              invalid_domain_SC/2,
              invalid_range_SC/2,             % OWL
              domain_not_subsumed_SC/2,
              range_not_subsumed_SC/2,         % OWL
              invalid_RDFS_property_SC/2    % OWL
          ]).

/** <module> Schema Validation
 *
 * This module deals with schema validation predicates as well as queries
 * for subsumption, domains, ranges, classes etc.
 *
 * * * * * * * * * * * * * COPYRIGHT NOTICE  * * * * * * * * * * * * * * *
 *                                                                       *
 *  This file is part of TerminusDB.                                      *
 *                                                                       *
 *  TerminusDB is free software: you can redistribute it and/or modify    *
 *  it under the terms of the GNU General Public License as published by *
 *  the Free Software Foundation, under version 3 of the License.        *
 *                                                                       *
 *                                                                       *
 *  TerminusDB is distributed in the hope that it will be useful,         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of       *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *
 *  GNU General Public License for more details.                         *
 *                                                                       *
 *  You should have received a copy of the GNU General Public License    *
 *  along with TerminusDB.  If not, see <https://www.gnu.org/licenses/>.  *
 *                                                                       *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

:- use_module(validate_instance).

:- reexport(core(util/syntax)).
:- use_module(core(util)).

:- use_module(core(triple)).
:- use_module(core(query)).
:- use_module(core(transaction)).

/*
 * Vio JSON util
 */
pathify(L, JSON) :-
    pathify(L, 0, JSON).

pathify([],_N,[]).
pathify([URI|Rest],N,[JSON|JSON_Rest]) :-
    JSON = _{ 'vio:index' : _{ '@value' : N, '@type' : 'xsd:nonNegativeInteger' },
              'vio:path_component' : _{ '@value' : URI, '@type' : 'xsd:string' }
            },
    M is N + 1,
    pathify(Rest,M, JSON_Rest).

/*
OWL DL Syntactic correctness

It would be useful to do a complete check on the syntactic
correctness of our ontology according to the OWL 2 / RDF mapping
*/

/*
Classes
*/

/**
 * immediate_class(?X:uri_or_id, +Database:database) is nondet.
 * immediate_class(+X:uri_or_id, +Database:database) is det.
 *
 * Check to see if class definitions are immediate (best practices) rather than inferred.
 *
 * @param X URI_OR_ID identifier for which to check if the schema has recorded a
 *        a non-inferred rfds or owl Class.
 * @param Schema Atom idntifying the current schema graph.
*/
immediate_class(X,Database) :-
    database_schema(Database,Schema),
    immediate_class_(X,Schema).

immediate_class_(X,Schema) :-
    xrdf(Schema, X, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'http://www.w3.org/2000/01/rdf-schema#Class').
immediate_class_(X,Schema) :-
    xrdf(Schema, X, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'http://www.w3.org/2002/07/owl#Class').
immediate_class_('http://www.w3.org/2002/07/owl#Thing',_).
immediate_class_('http://www.w3.org/2002/07/owl#Nothing',_).
% This makes me nervous... [ Gavin ]
immediate_class_('http://www.w3.org/2002/07/owl#Ontology', _).
% Should this be here?
immediate_class_('http://terminusdb.com/schema/system#Document', _).

%% class(?X:uri_or_id, +Schema:database is nondet
% class(+X:uri_or_id, +Schema:database is det
%
% All class designations - with inferences.
%
% @param X URI_OR_ID identifier for which to check if the schema has recorded a
%        an inferred rfds or owl Class.
% @param Database object with the current schema graph.
class(X,Database) :-
    database_schema(Database,Schema),
    class_(X,Schema).

class_(X,Schema) :- immediate_class_(X,Schema).
class_(X,Schema) :- sub_class_of_(X,Y,Schema), class_(Y,Schema).
class_(X,Schema) :- equivalent_class_(X,Y,Schema), class_(Y,Schema).


%
% immediate_restriction(+R:uri_or_id, +Database:database) is nondet.
%
immediate_restriction(R,Database) :-
    database_schema(Database,Schema),
    immediate_restriction_(R,Schema).

immediate_restriction_(R,Schema) :-
    xrdf(Schema, R, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'http://www.w3.org/2002/07/owl#Restriction').

immediate_class_or_restriction(R_or_C,Database) :-
    database_schema(Database,Schema),
    immediate_class_or_restriction_(R_or_C,Schema).

immediate_class_or_restriction_(R_or_C,Schema) :-
    immediate_restriction_(R_or_C,Schema),
    !.
immediate_class_or_restriction_(R_or_C,Schema) :-
    immediate_class_(R_or_C,Schema).


% restriction(+R:uri_or_id, +Database:database) is nondet.
%
% All restriction designations - with inferences.
%
% @param R URI_OR_ID identifier for which to check if the schema has recorded a
%        an inferred owl Restriction.
% @param Database identifying the current schema graph.
restriction(R,Database) :-
    database_schema(Database,Schema),
    restriction_(R,Schema).

restriction_(R,Schema) :-
    immediate_restriction_(R,Schema).
restriction_(R,Schema) :-
    sub_class_of_(R,R2,Schema),
    restriction_(R2,Schema).
restriction_(R,Schema) :-
    equivalent_class_(R,R2,Schema),
    restriction_(R2,Schema).

%% no_immediate_class_SC(+Database:database -Reason:any) is nondet
%
% Check to see if a class is used without a class definition.
%
% @param Schema Database idntifying the current schema graph.
% @param Reason A prolog representation of a JSON Linked Data structure
%               detailing the violation.
no_immediate_class_SC(Database, Reason) :-
    database_schema(Database,Schema),
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#ObjectProperty'),
    domain(P,X,Database),
    \+ immediate_class(X,Database), \+ restriction(X,Database),
    interpolate([X,' is used as a domain for property ',P,' but is not defined'], Message),
    Reason = _{
                 '@type' : 'vio:InvalidClassInDomain',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' }
             }.
no_immediate_class_SC(Database, Reason) :-
    database_schema(Database,Schema),
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#ObjectProperty'),
    range(P,X,Database),
    \+ immediate_class(X,Database), \+ restriction(X,Database),
    interpolate([X,' is used as a range for property ',P,' but is not defined'], Message),
    Reason = _{
                 '@type' : 'vio:Invalid_classIn_range',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' }
             }.
no_immediate_class_SC(Database, Reason) :-
    sub_class_of(X,Y,Database),
    \+ custom_datatype(X,Database), \+ immediate_class(X,Database), \+ restriction(X,Database),
    interpolate(['The class ',Y,' is not a superclass of a defined class ',X], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.
no_immediate_class_SC(Database, Reason) :-
    intersection_of(X,Y,Database),
    \+ immediate_class(X,Database), \+ restriction(X,Database),
    interpolate(['The class ',X,' is an intersection of ', Y,' but not a defined class'], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.
no_immediate_class_SC(Database, Reason) :-
    union_of(X,Y,Database),
    \+ immediate_class(Y,Database), \+ restriction(Y,Database),
    interpolate(['The class ',X,' is not a union of a defined class ',Y], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.

%% restriction_on_property(?CR:uri_or_id, ?P:uri_or_id, +Database:database) is nondet
%
% Defines the relation between properties and their restrictions.
%
% @param CR A restriction class specified as a URI_OR_ID
% @param P A property specified as a URI_OR_ID
% @param Database the current graph
restriction_on_property(CR,P,Database) :-
    database_schema(Database,Schema),
    restriction_on_property_(CR,P,Schema).

:- table restriction_on_property/3.
restriction_on_property_(CR,P,Schema) :-
	xrdf(Schema,CR,'http://www.w3.org/2002/07/owl#onProperty',P),
	restriction_(CR,Schema).
restriction_on_property_(CR,P,Schema) :-
	strict_subsumption_property_of_(P,Q,Schema),
	restriction_on_property_(CR,Q,Schema).

%% class_or_restriction(?X:uri_or_id, +Database:database is nondet
%
% All URI_OR_IDs which are either a class or restriction.
%
% @param X A class or restriction class specified as a URI_OR_ID
% @param Database The current graph
class_or_restriction(X,Database) :-
    database_schema(Database,Schema),
    class_or_restriction_(X,Schema).

class_or_restriction_(X,Schema) :- class_(X,Schema).
class_or_restriction_(X,Schema) :- restriction_(X,Schema).

% TODO: compound is vague, reasons should have a specification.

%% not_unique_class(+Y:uri_or_id, +Database:database, -Reason:any) is nondet
%
% Is a class multiply defined?
%
% @param Y A class specified as a URI_OR_ID
% @param Schema The current schema graph
not_unique_class(Y, Database, Reason) :-
    class_or_restriction(Y, Database),
    bagof(Y, class_or_restriction(Y, Database), L),
    \+ length(L,1),
    interpolate(['The class or restriction ',Y,
		         ' is not a unique. Some existing class has this identifier'],
		        Message),
    Reason = _{
                 '@type' : 'vio:Invalid_classViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.
not_unique_class_SC(Database,Reason) :- not_unique_class(_,Database,Reason).


%% collect(+collection:atom, +Database_ID:graph_identifier, +X:uri_or_id, -L:any) is semidet
%
% Collect the RDF list into a prolog list.
% It may be better to treat lists programmatically through rdf rather than
% collect them, using a derived predicate like rdf_listMembership
%
% @param Database Ignored
% @param Graphs The graphs to search for the list
% @param X The URI_OR_ID of an RDF list
% @param L Term
collect(_Database,Graphs,X,List) :-
    collect_(Graphs,X,List).

collect_(_,'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil',[]) :-
    !.
collect_(Graphs,X,[H|T]) :-
    xrdf(Graphs,X,'http://www.w3.org/1999/02/22-rdf-syntax-ns#first',H),
    !, % assume one result
    xrdf(Graphs,X,'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest',Y),
    !, % assume one result
    collect_(Graphs,Y,T).

%% sub_class_of(?Child:uri_or_id,?Parent:uri_or_id,+Database:database is nondet
%
% One step subclassing (only gives the immediate child-parent class relationship)
%
% @param Child Child class URI_OR_ID
% @param Parent Parent class URI_OR_ID.
sub_class_of(Child,Parent,Database) :-
    % TODO: Query only schema with ask
    database_schema(Database,Schema),
    sub_class_of_(Child,Parent,Schema).

sub_class_of_(Child,Parent,Schema) :-
    xrdf(Schema,Child, 'http://www.w3.org/2000/01/rdf-schema#subClassOf', Parent).

%% union_of(?Super:uri_or_id,?Sub:uri_or_id,+Database:database is nondet
%
% Gives URI_OR_ID solutions for which the Super URI_OR_ID is determined to be a union of.
%
% @param Super The class URI_OR_ID which is the union of other classes.
% @param Sub The class URI_OR_ID which is unioned to form the Super class.
% @param Database The current graph
union_of(C,U,Database) :-
    database_schema(Database,Schema),
    union_of_(C,U,Schema).

union_of_(C,U,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#unionOf',ListObj),
    collect_(Schema,ListObj,L),
    member(U,L).

%% union_of_list(+Super:uri_or_id,-Sub:list(uri_or_id),+Database:database is det
%
% Gives a list of URI_OR_IDs which are solutions for which the Super URI_OR_ID is determined to be a union of.
%
% @param Super The class URI_OR_ID which is the union of other classes.
% @param Sub The class URI_OR_ID which is unioned to form the Super class.
% @param Database The current graph
union_of_list(C,UList,Database) :-
    database_schema(Database,Schema),
    union_of_list_(C,UList,Schema).

union_of_list_(C,UList,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#unionOf',ListObj),
    collect_(Schema,ListObj,UList),
    % This looks so dubious, I hope I didn't write it.
    !.

%% disjoint_union_of(?Super:uri_or_id,?Sub:uri_or_id,+Database:database is nondet
%
% Gives URI_OR_ID solutions for which the Super URI_OR_ID is determined to be a union of.
%
% @param Super The class URI_OR_ID which is the disjoint union of other classes.
% @param Sub A class URI_OR_ID which is disjointly unioned to form the Super class.
% @param Database The current graph
%% :- rdf_meta disjoint_union_of(r,r,o).
disjoint_union_of(C,U,Database) :-
    database_schema(Database,Schema),
    disjoint_union_of_(C,U,Schema).

disjoint_union_of_(C,U,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#disjointUnionOf',ListObj),
    collect_(Schema,ListObj,L),
    member(U,L).

%% disjoint_union_of_list(+Super:uri_or_id,-Sub_list:list(uri_or_id),+Database:database is det
%
% Gives URI_OR_ID solutions as a list for which the Super URI_OR_ID is determined to be a djsoint union of.
%
% @param Super The class URI_OR_ID which is the disjoint union of other classes.
% @param Sub_list The prolog list of class URI_OR_IDs which are disjointly unioned to form the Super class.
% @param Database The current schema graph.
%% :- rdf_meta disjoint_unionOf_list(r,r,o).
disjoint_union_of_list(C,UList,Database) :-
    database_schema(Database,Schema),
    disjoint_union_of_list_(C,UList,Schema).

disjoint_union_of_list_(C,UList,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#disjointUnionOf',ListObj),
    collect_(Schema,ListObj,UList),
    % DUBIOUS
    !.

%% intersection_of(?Inter:uri_or_id,?Class:uri_or_id,+Database:database is nondet
%
% Gives URI_OR_ID solutions for which the Super URI_OR_ID is determined to be an intersection.
%
% @param Inter The class URI_OR_ID which is the intersection of the Class URI_OR_ID.
% @param Class A class URI_OR_ID of which Inter is an intersection.
% @param Database The current schema graph
%% :- rdf_meta intersection_of(r,r,o).
intersection_of(C,I,Database) :-
    database_schema(Database,Schema),
    intersection_of_(C,I,Schema).

intersection_of_(C,I,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#intersectionOf',ListObj),
    collect_(Schema,ListObj,L),
    member(I,L).

%% intersection_of_list(+Inter:uri_or_id,-Classes:list(uri_or_id),+Database:database is det
%
% Gives URI_OR_ID solutions as a list for which the Super URI_OR_ID is determined to be an intersection.
%
% @param Inter The class URI_OR_ID which is the disjoint union of other classes.
% @param Classes The prolog list of class URI_OR_IDs which are intersected.
% @param Database The current schema graph.
intersection_of_list(C,IList,Database) :-
    database_schema(Database,Schema),
    intersection_of_list_(C,IList,Schema).

intersection_of_list_(C,IList,Schema) :-
    xrdf(Schema, C,'http://www.w3.org/2002/07/owl#intersectionOf',ListObj),
    collect_(Schema,ListObj,IList),
    !.

%% one_of(?CC:uri_or_id,?X:uri_or_id,+Database:database is det
%
% Gives elements which are members of a class by enumeration.
%
% @param Collection,Schema,CC The class URI_OR_ID of which X isr.
% @param X The URI_OR_ID of the element which is a member of CC.
% @param Database The current schema graph.
%% :- rdf_meta one_of(r,r,o).
one_of(CC,X,Database) :-
    database_schema(Database,Schema),
    one_of_(CC,X,Schema).

one_of_(CC,X,Schema) :-
    xrdf(Schema,CC,'http://www.w3.org/2002/07/owl#oneOf',ListObj),
    collect_(Schema,ListObj,OneList),
    member(X,OneList).

%% one_of_list(+CC:uri_or_id,-OneList:list(uri_or_id),+Database:database is det
%
% Gives a prolog list of elements associated with an enumerated class.
%
% @param CC The class URI_OR_ID of which X is a member.
% @param OneList The URI_OR_ID list of elements which are members of CC.
% @param Database The current schema graph.
%% :- rdf_meta one_of_list(r,r,o).
one_of_list(C,OneList,Database) :-
    database_schema(Database,Schema),
    one_of_list_(C,OneList,Schema).

one_of_list_(C,OneList,Schema) :-
    xrdf(Schema,C,'http://www.w3.org/2002/07/owl#oneOf',ListObj),
    collect_(Schema,ListObj,OneList).

%% :- rdf_meta complement_of(r,r,o).
complement_of(CC,CN,Database) :-
    database_schema(Database,Schema),
    complement_of_(CC,CN,Schema).

complement_of_(CC,CN,Schema) :-
    xrdf(Schema,CC,'http://www.w3.org/2002/07/owl#complementOf',CN).

%% :- rdf_meta datatype_complementOf(r,r,o).
datatype_complementOf(CC,CN,Database) :-
    database_schema(Database,Schema),
    datatype_complementOf_(CC,CN,Schema).

datatype_complementOf_(CC,CN,Schema) :-
    xrdf(Schema,CC,'http://www.w3.org/2002/07/owl#datatypeComplementOf',CN).

%% :- rdf_meta equivalent_class(r,r,o).
equivalent_class(CC,CE,Database) :-
    database_schema(Database,Schema),
    equivalent_class_(CC,CE,Schema).

equivalent_class_(CC,CE,Schema) :-
    xrdf(Schema,CC,'http://www.w3.org/2002/07/owl#equivalentClass',CE).

/*  Previous code for equivalent class.
    xrdf('http://www.w3.org/2002/07/owl#equivalent_class',ListObj,Schema),
    collect(ListObj,L,Schema),
    member(CE,L). */

%% :- rdf_meta equivalent_class(r,r,o).
anonymous_equivalentClass(C,CE,Database) :-
    database_schema(Database,Schema),
    anonymous_equivalentClass_(C,CE,Schema).

anonymous_equivalentClass_(C,CE,Schema) :-
    equivalent_class_(C,CE,Schema),
    % Exactly one reference to this class, or everything will go to hell.
    bagof(X,xrdf(Schema,X,_,CE), [_]).

% transitive strict relation
sub_class_strict(X,Y,Database) :-
    database_schema(Database,Schema),
    sub_class_strict_(X,Y,Schema).

sub_class_strict_(X,Y,Schema) :- sub_class_of_(X,Y,Schema).
sub_class_strict_(X,Z,Schema) :-
    sub_class_of_(X,Y,Schema),
    sub_class_strict_(Y,Z,Schema).

% Implements class subsumption
% - complement_of classes do not give subsumption properly yet (unimplemented).
%   Requires anti-subsumption predicate
% - one_of should probably have individual sets for both CC, CP
%
% static solutions first.
/*
subsumption_of(CC,CP,Database) :-
    database_schema(Database,Schema),
    subsumption_of_(CC,CP,Schema).
*/

subsumption_of(CC,CP,Database) :-
    (   is_database_schema_compiled(Database)
    ->  true
    ;   compile_schema(Database)),
    compiled_subsumption_of(CC,CP,Database).

:- dynamic compiled_subsumption_of_/3.
:- dynamic schema_identifier_/2.

compiled_subsumption_of(CC,CP,Database) :-
    schema_identifier(Database,Schema_Id),
    compiled_subsumption_of_(Schema_Id,CC,CP).

schema_identifier(Database, Schema_Id) :-
    get_dict(descriptor, Database, DB_Desc),
    schema_identifier_(DB_Desc, Schema_Id),
    !.
schema_identifier(Database, Schema_Id) :-
    get_dict(descriptor, Database, DB_Desc),
    format(string(Canonical), "~q", [DB_Desc]),
    md5_hash(Canonical, Schema_Id, []),
    assertz(schema_identifier_(DB_Desc,Schema_Id)).

is_database_schema_compiled(Database) :-
    get_dict(descriptor, Database, DB_Desc),
    schema_identifier_(DB_Desc,_Schema_Id).

compile_schema(Database) :-
    schema_identifier(Database,Schema_Id),
    compile_subsumption(Database,Schema_Id).

compile_subsumption(Database,Schema_Id) :-
    database_schema(Database,Schema),
    forall(
        subsumption_of_(CC,CP,Schema),
        (   compiled_subsumption_of_(Schema_Id,CC,CP)
        ->  true
        ;   assertz(compiled_subsumption_of_(Schema_Id,CC,CP)))).

invalidate_schema(Database) :-
    schema_identifier(Database,Schema_Id),
    with_mutex(
        Schema_Id,
        (   retractall(schema_identifier_(_,Schema_Id)),
            retractall(compiled_subsumption_of_(Schema_Id,_,_)))).

:- table subsumption_of_/3.
subsumption_of_(_,'http://www.w3.org/2002/07/owl#Thing',_).
subsumption_of_(CC,CC,Schema) :-
    immediate_class_or_restriction_(CC,Schema).
subsumption_of_(CC,CP,Schema) :-
    sub_class_of_(CC,CZ,Schema),
    subsumption_of_(CZ,CP,Schema).
subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    union_of_(CZ,CC,Schema),
    subsumption_of_(CZ,CP,Schema).
subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    disjoint_union_of_(CZ,CC,Schema),
    subsumption_of_(CZ,CP,Schema).
subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    intersection_of_(CC,CZ,Schema),
    subsumption_of_(CZ,CP,Schema).
subsumption_of_(CC,CP,Schema) :-
    anonymous_equivalentClass_(CC,CZ,Schema),
    subsumption_of_(CZ,CP,Schema).
subsumption_of_(CC,CP,Schema) :- % datatypes
    datatype_(CC,Schema),
    datatype_subsumption_of_(CC,CP,Schema).

%% :- rdf_meta custom_datatype(r,o).
custom_datatype(X,Database) :-
    database_schema(Database,Schema),
    custom_datatype_(X,Schema).

custom_datatype_(X,Schema) :-
    xrdf(Schema,X, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'http://www.w3.org/2000/01/rdf-schema#Datatype').

/**
 * datatype(-X:uri_or_id,+Database:database) is nondet.
 * datatype(-X:uri_or_id,+Database:database) is det.
 */
%% :- rdf_meta datatype(r,o).
datatype(X,Database) :-
    database_schema(Database,Schema),
    datatype_(X,Schema).

datatype_(X,Schema) :- custom_datatype_(X,Schema).
datatype_(X,_) :- base_type(X).

% implements strict class subsumption (CC < CP) [Needs fully instantiated arguments]
%% :- rdf_meta strict_subsumption_of(r,r,o).
strict_subsumption_of(CC,CP,Database) :-
    database_schema(Database,Schema),
    strict_subsumption_of_(CC,CP,Schema).

strict_subsumption_of_(CC,'http://www.w3.org/2002/07/owl#Thing',_) :- CC \= 'http://www.w3.org/2002/07/owl#Thing'.
strict_subsumption_of_('http://www.w3.org/2002/07/owl#Nothing',CP,_) :- CP \= 'http://www.w3.org/2002/07/owl#Nothing'.
strict_subsumption_of_(CC,CP,Schema) :-
    sub_class_of_(CC,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    union_of_(CP,CC,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    intersection_of_(CC,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    sub_class_of_(CC,CZ,Schema),
    strict_subsumption_of_(CZ,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    union_of_(CZ,CC,Schema),
    strict_subsumption_of_(CZ,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    disjoint_union_of_(CZ,CC,Schema),
    strict_subsumption_of_(CZ,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :-
    immediate_class_or_restriction_(CC,Schema),
    intersection_of_(CC,CZ,Schema),
    strict_subsumption_of_(CZ,CP,Schema).
strict_subsumption_of_(CC,CP,Schema) :- % xsd and custom data types
    datatype_strict_subsumption_of_(CC,CP,Schema).

/**
 * basetype_subsumption_of(?Sub,?Super) is nondet.
 *
 * Implements the subsumption latice for concrete base types by making use of reflexivity and
 * base_type_parent\2.
 */
%% :- rdf_meta basetype_subsumption_of(r,r).
basetype_subsumption_of(T,T) :- base_type(T).
basetype_subsumption_of(Sub,Super) :-
    base_type_parent(Sub,Parent), basetype_subsumption_of(Parent,Super).

/**
 * datatype_subsumption_of(?Sub,?Super,+Database:database) is nondet.
 *
 * Implements the subsumption latice for datatypes by making use of reflexivity and
 * base_type_parent\2.
 */
datatype_subsumption_of(Sub,Super,Database) :-
    database_schema(Database,Schema),
    datatype_subsumption_of(Sub,Super,Schema).

datatype_subsumption_of_(T,T,Schema) :- datatype_(T,Schema).
datatype_subsumption_of_(Sub,Super,Schema) :-
    custom_datatype_(Sub,Schema),
    union_of_(Super,Sub,Schema).
datatype_subsumption_of_(Sub,Super,Schema) :-
    custom_datatype_(Sub,Schema),
    intersection_of_(Sub,Super,Schema).
datatype_subsumption_of_(Sub,Super,Schema) :-
    % This only works because of the strict hierarchy (no derived union / intersections)
    custom_datatype_(Sub,Schema),
    datatype_complementOf_(Sub,CN,Schema),
    \+ datatype_subsumption_of_(CN,Super,Schema).
datatype_subsumption_of_(Sub,Super,Schema) :-
    base_type_parent(Sub,Parent), datatype_subsumption_of_(Parent,Super,Schema).

/**
 * datatype_subsumption_of(?Sub,?Super,+Database:database) is nondet.
 *
 * Implements strict (non reflexive) subsumption latice for datatypes by
 * base_type_parent/2.
 */
%% :- rdf_meta datatype_strict_subsumption_of(r,r).
datatype_strict_subsumption_of(Sub,Super,Database) :-
    database_schema(Database,Schema),
    datatype_strict_subsumption_of_(Sub,Super,Schema).

datatype_strict_subsumption_of_(Sub,Super,_) :-
    base_type_parent(Sub,Super).
datatype_strict_subsumption_of_(Sub,Super,Schema) :-
    % DDD probably need one more clause for each owl custom build property
    base_type_parent(Sub,Parent),
    datatype_subsumption_of_(Parent,Super,Schema).

/**
 * orphan_class_SC(+Database:database-Reason:vio) is nondet.
 *
 * Find all orphaned classes in Schema.
 */
orphan_class_SC(Database, Reason) :-
    sub_class_of(X,Y,Database),
    \+ class(Y,Database), \+ restriction(Y,Database),
    interpolate(['The class ',X,' is not a subclass of a valid class ',Y], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.
orphan_class_SC(Database, Reason) :-
    intersection_of(X,Y,Database),
    \+ class(Y,Database), \+ restriction(Y,Database),
    interpolate(['The class ',X, ' is not an intersection of a valid class ',Y], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.
orphan_class_SC(Database, Reason) :-
    union_of(X,Y,Database),
    \+ class(Y,Database), \+ restriction(Y,Database),
    interpolate(['The class ',X,' is not a union of a valid class ',Y], Message),
    Reason = _{
                 '@type' : 'vio:ClassInheritanceViolation',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI' },
	             'vio:parent' : _{ '@value' : Y, '@type' : 'xsd:anyURI' }
             }.

% Cycles in subsumption diagram
class_cycle_help(C,S,[],_) :- get_assoc(C,S,true), !.
class_cycle_help(C,S,[K|P],Database) :-
    sub_class_of(K,C,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    union_of(C,K,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    disjoint_union_of(C,K,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    intersection_of(K,C,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    equivalent_class(K,C,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    complement_of(K,C,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).
class_cycle_help(C,S,[K|P],Database) :-
    datatype_complementOf(K,C,Database),
    put_assoc(C,S,true,S2), class_cycle_help(K,S2,P,Database).

class_cycle(C,P,Database,Reason) :-
    empty_assoc(S), class_cycle_help(C,S,P,Database),
    interpolate(['Class, ',C,' has a class cycle with path: ', P], Message),
    pathify(P,JSON),
    Reason = _{
                 '@type' : 'vio:ClassCycle',
                 'vio:path' : JSON,
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:class' : _{ '@value' : C, '@type' : 'xsd:anyURI' }
             }.

class_cycle_SC(Database,Reason) :- class_cycle(_,_,Database,Reason), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Properties

/*
:- rdf_meta rdfs_property(r).
rdfs_property(rdfs:label).
rdfs_property(rdfs:comment).
rdfs_property(rdfs:seeAlso).
*/

%:- rdf_meta rdf_meta_property(r).
rdf_meta_property('http://www.w3.org/1999/02/22-rdf-syntax-ns#type').

%:- rdf_meta rdfs_datatype_property(r).
rdfs_datatype_property('http://www.w3.org/2000/01/rdf-schema#label').
rdfs_datatype_property('http://www.w3.org/2000/01/rdf-schema#comment').

%:- rdf_meta rdfs_object_property(r).
rdfs_object_property('http://www.w3.org/2000/01/rdf-schema#seeAlso').

%:- rdf_meta rdfs_property(r).
rdfs_property(P) :- rdfs_datatype_property(P).
rdfs_property(P) :- rdfs_object_property(P).

%:- rdf_meta rdf_property(r,o).
rdf_property(P,Database) :-
    database_schema(Database,Schema),
    rdf_property_(P,Schema).

rdf_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/1999/02/22-rdf-syntax-ns#Property').

%:- rdf_meta datatype_property(r,o).
datatype_property(P,Database) :-
    database_schema(Database,Schema),
    datatype_property_(P,Schema).

datatype_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#DatatypeProperty').
datatype_property_(P,_) :- rdfs_datatype_property(P).

%:- rdf_meta annotation_property(r,o).
annotation_property(P,Database) :-
    database_schema(Database,Schema),
    annotation_property_(P,Schema).

annotation_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#AnnotationProperty').

%:- rdf_meta functional_property(r,o).
functional_property(P,Database) :-
    database_schema(Database,Schema),
    functional_property_(P,Schema).

functional_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#FunctionalProperty').

%:- rdf_meta inverse_functional_property(r,o).
inverse_functional_property(P,Database) :-
    database_schema(Database,Schema),
    inverse_functional_property_(P,Schema).

inverse_functional_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#InverseFunctionalProperty').

%:- rdf_meta object_property(r,o).
object_property(P,Database) :-
    database_schema(Database,Schema),
    object_property_(P,Schema).

object_property_(P,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/1999/02/22-rdf-syntax-ns#type','http://www.w3.org/2002/07/owl#ObjectProperty').
object_property_(P,_) :- rdfs_object_property(P).

/**
 * property(?P,+Database:database) is nondet.
 *
 * ?P is a valid property in the schema.
 */
%:- rdf_meta property(r,o).
property(P,Database) :-
    database_schema(Database,Schema),
    property_(P,Schema).

property_(P,Schema) :-
    % Don't predicate over annotations (even if they are otherwise declared as properties).
    (   annotation_property_(P,Schema)
    *-> fail
    ;   (   datatype_property_(P, Schema)
        ;   object_property_(P,Schema)
        ;   rdf_property_(P,Schema)
        )
    ).

%unique_property(P,Database) :- property(P,Database), bagof(P2, property(P2,Database), L), count(P,L,1).

not_unique_property(P,Database,Reason) :-
    property(P,Database),
    bagof(P, property(P,Database), L),
    \+ length(L,1),
    %break,
    interpolate([P,' is not a unique property name, some property with this name already exists'],
		        Message),
    Reason = _{
                 '@type' : 'vio:NonUniquePropertyName',
	             'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' }
             }.

property_type_overload_SC(Database,Reason) :-
    datatype_property(P,Database), object_property(P,Database),
    interpolate([P,' is an object_property and a datatype_property'], Message),
    Reason= _{
                '@type' : 'vio:PropertyTypeOverload',
                'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
	            'vio:property' :  _{ '@value' : P, '@type' : 'xsd:anyURI' }
            }.

annotation_overload_SC(Database,Reason) :-
    (datatype_property(P,Database) ; object_property(P,Database) ; rdf_property(P,Database)),
    annotation_property(P,Database),
    interpolate([P,' is defined as a property and defined as an annotation_property'], Message),
    Reason= _{
                '@type' : 'vio:PropertyTypeOverload',
                'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
	            'vio:property' :  _{ '@value' : P, '@type' : 'xsd:anyURI' }
            }.

/**
 * not_unique_property_SC(+Database:database-Reason:any) is nondet.
 *
 * All redundantly defined properties.
 */
not_unique_property_SC(Database,Reason) :-
    not_unique_property(_,Database, Reason).

% One step subproperty relation
%:- rdf_meta sub_property_of(r,r,o).
sub_property_of(X,Y,Database) :-
    database_schema(Database,Schema),
    sub_property_of_(X,Y,Schema).

sub_property_of_(X,Y,Schema) :-
    xrdf(Schema,X,'http://www.w3.org/2000/01/rdf-schema#subPropertyOf',Y).

/**
 * subsumption_properties_of(?PChild,?PParent,+Database:database) is nondet.
 *
 * Transitive reflexive closure of Subproperty relation.
 */
subsumption_properties_of(PC,PP,Database) :-
    database_schema(Database,Schema),
    subsumption_properties_of_(PC,PP,Schema).

subsumption_properties_of_(PC,PC,_).
subsumption_properties_of_(PC,PP,Schema) :-
    sub_property_of_(PC, PZ, Schema),
    subsumption_properties_of_(PZ,PP,Schema).
subsumption_properties_of_(PC,'http://www.w3.org/2002/07/owl#topObjectProperty',Schema) :-
    object_property_(PC,Schema).
subsumption_properties_of_(PC,'http://www.w3.org/2002/07/owl#topDataProperty',Schema) :-
    datatype_property_(PC,Schema).

/**
 * strict_subsumption_property_of(?PChild,?PParent,-Database:database) is nondet.
 *
 * Non-reflexive subsumption relation for properties in Database.
 */
strict_subsumption_property_of(PC,PP,Database) :-
    database_schema(Database,Schema),
    strict_subsumption_property_of_(PC,PP,Schema).

:- table strict_subsumption_property_of_/3.
strict_subsumption_property_of_(PC,PP,Schema) :-
    sub_property_of_(PC, PP, Schema).
strict_subsumption_property_of_(PC,PP,Schema) :-
    sub_property_of_(PC, PZ, Schema),
    subsumption_properties_of_(PZ,PP,Schema).
strict_subsumption_property_of_(PC,'http://www.w3.org/2002/07/owl#topObjectProperty',Schema) :-
    % What is this?
    PC \= 'http://www.w3.org/2002/07/owl#top_objectProperty',
    object_property_(PC,Schema).
strict_subsumption_property_of_(PC,'http://www.w3.org/2002/07/owl#topDataProperty',Schema) :-
    % What is this?
    PC \= 'http://www.w3.org/2002/07/owl#top_dataProperty',
    datatype_property_(PC,Schema).

orphan_property(X,Y,Database,Reason) :-     % is a subproperty of Y but Y is not a valid property
    sub_property_of(X,Y,Database),
    \+ property(Y,Database), \+ annotation_property(Y,Database),
    interpolate([X,' is a sub-property of', Y,' which is not designated as a property of any type in the schema!' ], Message),
    Reason= _{
                '@type' : 'vio:Property_inheritanceViolation',
                'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
	            'vio:property' :  _{ '@value' : X, '@type' : 'xsd:anyURI' },
                'vio:parent_property' :  _{ '@value' : Y, '@type' : 'xsd:anyURI' }
            }.
orphan_property(P,R,Database,Reason) :-  % property has a range but it is not the property of a Classs
	range(P,R,Database),
    \+ property(P,Database), \+ annotation_property(P,Database),
	interpolate([P,' has a range, but is not designated as a property of any type in the schema!'],Message),
    Reason= _{
                '@type' : 'vio:Untyped_propertyWith_range',
                'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
	            'vio:property' :  _{ '@value' : P, '@type' : 'xsd:anyURI' },
                'vio:range' :  _{ '@value' : R, '@type' : 'xsd:anyURI' }
            }.
orphan_property(P,D,Database,Reason) :-     %% property has a domain but it is not the property of a Classs
	domain(P,D,Database),
    \+ property(P,Database), \+ annotation_property(P,Database),
    interpolate([P,' has a domain, but is not designated as a property of any type in the schema!'],Message),
    Reason= _{
                '@type' : 'vio:Untyped_propertyWith_domain',
                'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
	            'vio:property' :  _{ '@value' : P, '@type' : 'xsd:anyURI' },
                'vio:domain' :  _{ '@value' : D, '@type' : 'xsd:anyURI' }
            }.

/**
 * orphan_property_SC(+Database:database-Reason:any) is nondet.
 *
 * All properties which are referred to, but which do not have definitions.
 */
orphan_property_SC(Database,Reason) :-
    orphan_property(_,_,Database,Reason).

% sub_property cycles

property_cycle_help(P,S,[],_) :- get_assoc(P,S,true), !.
property_cycle_help(P,S,[Q|T],Database) :-
    property(P,Database), sub_property_of(Q,P,Database), put_assoc(P, S, true, S2),
    property_cycle_help(Q,S2,T,Database).

property_cycle(P,PC,Database,Reason) :-
    empty_assoc(S), property_cycle_help(P,S,PC,Database),
    interpolate(['Property class ', P, ' has a cycle with path: ', PC], Message),
    pathify(PC, JSON),
    Reason = _{
                 '@type' : 'vio:ClassCycle',
                 'vio:propertyCycle' : JSON,
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' }
             }.

/**
 * property_cycle_SC(+Database:database-Reason:any) is nondet.
 *
 * All property subsumption cycles in Database.
 */
property_cycle_SC(Database,Reason) :- property_cycle(_,_,Database,Reason).

/**
 * range(?P:uri, ?R:uri, +Database:database) is nondet.
 *
 * Actually specified range for P.
 */
range(P,R,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,P,'http://www.w3.org/2000/01/rdf-schema#range',R).

/**
 * document(?Class,+Database) is nondet.
 *
 * This is a foundational predicate for DQS which establishes
 * the places in which to "clip" the graph.
 */
document(Class,Database) :-
	subsumption_of(Class,'http://terminusdb.com/schema/system#Document', Database).

/**
 * any_range(?P,?R,+Database:database) is nondet.
 *
 * Determine if R is a viable range for P.
 * This must be ordered according to Hasse diagram!
 */
%:- rdf_meta any_range(r,r,o).
any_range('http://www.w3.org/2002/07/owl#topObjectProperty','http://www.w3.org/2002/07/owl#Thing',_).
any_range('http://www.w3.org/2002/07/owl#topDataProperty','http://www.w3.org/2000/01/rdf-schema#Literal',_).
any_range('http://www.w3.org/2000/01/rdf-schema#label','http://www.w3.org/2001/XMLSchema#string',_).
any_range('http://www.w3.org/2000/01/rdf-schema#comment','http://www.w3.org/2001/XMLSchema#string',_).
any_range(P,R,Database) :-
    range(P,R,Database).
any_range(P,R,Database) :-
    strict_subsumption_property_of(P,P2,Database),
    any_range(P2,R,Database).
any_range(OP,R,Database) :-
    database_inference(Database,Inference),
    xrdf(Inference,OP,'http://www.w3.org/2002/07/owl#inverseOf',P),
    any_domain(P,R,Database).

%:- rdf_meta most_specific_range(r,r,o).
most_specific_range(P,R,Database) :- any_range(P,R,Database), !.

/**
 * domain(P:uri,D:uri,Database:database) is nondet.
 *
 * Actually specified domain in the database.
 */
domain(P,D,Database) :-
    database_schema(Database,Schema),
    domain_(P,D,Schema).

:- table domain_/3.
domain_(P,D,Schema) :-
    xrdf(Schema,P,'http://www.w3.org/2000/01/rdf-schema#domain',D).

/**
 * any_domain(?P,?R,+Database:database) is nondet.
 *
 * Determine if R is a viable domain for P.
 */
%:- rdf_meta any_domain(r,r,o).
any_domain('http://www.w3.org/2002/07/owl#topObjectProperty',
          'http://www.w3.org/2002/07/owl#Thing',_).
any_domain('http://www.w3.org/2002/07/owl#topDataProperty',
          'http://www.w3.org/2000/01/rdf-schema#Literal',_).
any_domain('http://www.w3.org/2000/01/rdf-schema#label',D,Database) :-
    document(D,Database).
any_domain('http://www.w3.org/2000/01/rdf-schema#comment',D,Database) :-
    document(D,Database).
any_domain(P,R,Database) :-
    domain(P,R,Database).
any_domain(OP,R,Database) :-
    database_inference(Database,Inference),
    xrdf(Inference,OP,'http://www.w3.org/2002/07/owl#inverseOf',P),
    any_range(P,R,Database).
any_domain(P,R,Database) :-
    strict_subsumption_property_of(P,P2,Database),
    any_domain(P2,R,Database).

% TODO inverse isn't enough! need to do more inference

%:- rdf_meta most_specific_domain(r,r,o).
most_specific_domain(P,R,Database) :- any_domain(P,R,Database), !.

/**
 * no_immediate_domain_SC(+Database:database-Reason:vio) is nondet.
 *
 * All properties which do not have a specified domain.
 */
no_immediate_domain_SC(Database,Reason) :-
    property(P,Database),
    \+ rdfs_property(P),
    \+ domain(P,_,Database),
    (   datatype_property(P,Database)
    ->  M='Data property '
    ;   annotation_property(P,Database)
    ->  M='Annotation property '
    ;   object_property(P,Database)
    ->  M='Object property '
    ;   rdf_property(P,Database)
    ->  M='Rdf Property '
    ;   M='Unknown Property '),
    interpolate([M, P, ' has no specified domain.'], Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithNoDomain',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'}
             }.

/**
 * no_immediate_range_SC(+Database:database-Reason:vio) is nondet.
 *
 * All properties which do not have a specified range.
 */
no_immediate_range_SC(Database,Reason) :-
    property(P,Database),
    \+ rdfs_property(P),
    \+ range(P,_,Database),
    (   datatype_property(P,Database)
    ->  M='Data property '
    ;   annotation_property(P,Database)
    ->  M='Annotation property '
    ;   object_property(P,Database)
    ->  M='Object property '
    ;   rdf_property(P,Database)
    ->  M='Rdf Property '
    ;   M='Unknown Property '),
    interpolate([M, P, ' has no specified range.'], Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithNoRange',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'}
             }.

/**
 * invalid_domain_SC(+Database:database-Reason:any) is nondet.
 *
 * Finds all domains that are not valid classes for a given property in Database.
 */
invalid_domain_SC(Database,Reason) :-
    property(P,Database),
    domain(P,D,Database),
    \+ class(D,Database),
    interpolate(['The property ', P,' has an undefined domain.'],Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithUndefinedDomain',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:domain' : _{ '@value' : D, '@type' : 'xsd:anyURI'}
             }.

/**
 * invalid_RDFS_property_SC(+Database:database-Reason:any) is nondet.
 *
 * Finds all domains that are not valid classes for a given property in Database.
 */
invalid_RDFS_property_SC(Database,Reason) :-
    database_schema(Database,Schema),
    rdfs_property(P),
    xrdf(Schema,_,P,Y),
    refute_basetype_elt(Y,'http://www.w3.org/2001/XMLSchema#string',Reason).

/**
 * invalid_range_SC(+Database:database-Reason:any) is nondet.
 *
 * Finds all ranges that are not valid classes for a given property in Database.
 */
invalid_range_SC(Database,Reason) :-
    datatype_property(P,Database),
    range(P,R,Database),
    \+ datatype(R,Database), \+ rdfs_property(P),
    interpolate(['DataProperty Range ', R, ' is not a valid (or implemented) datatype for property ', P,'.'], Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithUndefinedRange',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:range' : _{ '@value' : R, '@type' : 'xsd:anyURI'}
             }.
invalid_range_SC(Database,Reason) :-
    object_property(P,Database),
    range(P,R,Database),
    \+ class(R,Database), \+ rdfs_property(P),
    interpolate(['Object_property Range ',R,' is not a valid range for property ',P,'.'],Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithUndefinedRange',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:range' : _{ '@value' : R, '@type' : 'xsd:anyURI'}
             }.
invalid_range_SC(Database,Reason) :-
    rdf_property(P,Database),
    range(P,R,Database),
    \+ class(R,Database), \+ base_type(R),
    interpolate(['rdf:Property range ',R,' is not a valid range for property ',P,'.'],Message),
    Reason = _{
                 '@type' : 'vio:PropertyWithUndefinedRange',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'},
                 'vio:range' : _{ '@value' : R, '@type' : 'xsd:anyURI'}
             }.



% Logging / Turn off for production
:- use_module(library(http/http_log)).
/**
 * domain_notSubsumedsC(+Database:database-Reason:any) is nondet.
 *
 * All domains which can not validly be subsumed within a property subsumption hierarchy for
 * the Database .
 */
domain_not_subsumed_SC(Database,Reason) :-
    property(P,Database),
    strict_subsumption_property_of(P,P2,Database),
    domain(P,D,Database), domain(P2,D2,Database), % DDD too many solutions
    %http_log_stream(Log),
    %current_output(Log),
    %findall(X, subsumption_of(D,X,Database), L),
    %nl(Log), nl(Log), write(Log, 'Subsumptions: '), write_canonical(Log, L), nl(Log), nl(Log),
    %nl(Log), nl(Log), write(Log, 'Listing: '), write_canonical(Log, L), nl(Log), nl(Log),
    \+ subsumption_of(D, D2, Database),
    interpolate(['Invalid domain on property ', P,
		         ', due to failure of domain subsumption.'], Message),
    Reason = _{
                 '@type' : 'vio:PropertyDomainNotSubsumed',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:parentProperty' : _{ '@value' : P2, '@type' : 'xsd:anyURI' },
                 'vio:class' : _{ '@value' : D, '@type' : 'xsd:anyURI'},
                 'vio:parent' : _{ '@value' : D2, '@type' : 'xsd:anyURI'},
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'}
             }.

/**
 * range_not_subsumed_SC(+Database:database-Reason:any) is nondet.
 *
 * Database constraint determining that ranges must be valid
 * a property through its entire subsumption chain.
 */
range_not_subsumed_SC(Database,Reason) :-
    property(P,Database),
    strict_subsumption_property_of(P,P2,Database),
    range(P,R,Database), range(P2,R2,Database), % DDD too many solutions
    \+ subsumption_of(R, R2, Database),
    interpolate(['Invalid range on property ', P,
		         ', due to failure of range subsumption.'], Message),
    Reason = _{
                 '@type' : 'vio:PropertyRangeNotSubsumed',
                 'vio:property' : _{ '@value' : P, '@type' : 'xsd:anyURI' },
                 'vio:parentProperty' : _{ '@value' : P2, '@type' : 'xsd:anyURI' },
                 'vio:class' : _{ '@value' : R, '@type' : 'xsd:anyURI'},
                 'vio:parent' : _{ '@value' : R2, '@type' : 'xsd:anyURI'},
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'}
             }.

schema_subject_blank_node(X,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,X,_,_),
    is_bnode(X).

schema_predicate_blank_node(Y,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,_,Y,_),
    is_bnode(Y).

schema_object_blank_node(Z,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,_,_,Z),
    is_bnode(Z).

/**
 * label(?X,?Y,+Database:database) is det.
 *
 * Get the rdfs:label for X as Y.
 */
label(X,Y,Database) :-
    database_instance(Database,Instance),
    xrdf(Instance,X, 'http://www.w3.org/2000/01/rdf-schema#label',Y).
label(X,Y,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,X, 'http://www.w3.org/2000/01/rdf-schema#label',Y).

/**
 * comment(?X,?Y,+Database:database) is det.
 *
 * Get the rdfs:comment for X as Y.
 */
comment(X,Y,Database) :-
    database_instance(Database,Instance),
    xrdf(Instance,X, 'http://www.w3.org/2000/01/rdf-schema#comment', Y).
comment(X,Y,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,X, 'http://www.w3.org/2000/01/rdf-schema#comment', Y).

/**
 * system_tag(?X:uri_or_id,?Y:any,+Database:database) is det.
 *
 * Get the system:tag for X as Y.
 */
system_tag(X,Y,Database) :-
    database_schema(Database,Schema),
    xrdf(Schema,X, 'http://terminusdb.com/schema/system#tag', Y).

class_has_label(X,Y,Database) :- class(X,Database), label(X,Y,Database).
%class_hasNo_label(X,Database) :- class(X,Database), \+ label(X,_,Database).

class_has_one_label(X,Database) :-
    class_has_label(X,Label,Database),
    bagof(label(Y,Label2), class_has_label(Y,Label2,Database), L), count(label(X,Label),L,1).

not_unique_class_label(X,Database,Reason) :-
    \+ class_has_one_label(X,Database),
    interpolate(['Class ', X,' does not have exactly one lable.'], Message),
    Reason = _{
                 '@type' : 'vio:DuplicateClassLabelViolation',
                 'vio:class' : _{ '@value' : X, '@type' : 'xsd:anyURI'},
                 'vio:message' : _{ '@value' : Message, '@type' : 'xsd:string'}
             }.

/**
 * not_unique_class_label_SC(+Database:database -Reason:vio) is nondet.
 *
 * What it says on the tin: every non unique label in Database as a schema constraint.
 */
not_unique_class_label_SC(Database,Reason) :- not_unique_class_label(_,Database,Reason).
