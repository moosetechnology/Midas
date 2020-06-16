Class {
	#name : #MiQueriesBrowser,
	#superclass : #MiAbstractBrowser,
	#instVars : [
		'queriesTree',
		'queryResult',
		'selectedQuery',
		'queries',
		'queryCode',
		'queriesToolbar'
	],
	#category : #'Midas-FamixQueries-Presenters'
}

{ #category : #specs }
MiQueriesBrowser class >> defaultSpec [
	^ super defaultSpec
		add:
			(SpPanedLayout newHorizontal
				add:
					(SpBoxLayout newVertical
						add: #queriesToolbar height: self toolbarHeight;
						add: #queriesTree;
						yourself);
				add:
					(SpPanedLayout newVertical
						add: #queryResult;
						add: #queryCode;
						yourself);
				yourself);
		yourself
]

{ #category : #'world menu' }
MiQueriesBrowser class >> menuCommandOn: aBuilder [
	<worldMenu>
	(aBuilder item: #Queries)
		parent: self toolbarName;
		label: 'Queries';
		action: [ self runMe ]
]

{ #category : #private }
MiQueriesBrowser class >> new [
	"A MooseGroup is necessary to initialize this presenter"

	^ self on: MooseGroup new
]

{ #category : #'instance creation' }
MiQueriesBrowser class >> open [
	<script>
	self
		flag:
			#FQImprove
				, 'This should be an example AND it depends on tests package'.
	^ (self on: FQTestsHelper current classesAndMethods)
		openWithSpec;
		yourself
]

{ #category : #'instance creation' }
MiQueriesBrowser class >> openEmpty [
	<script>
	^ self new
		openWithSpec;
		yourself
]

{ #category : #'world menu' }
MiQueriesBrowser class >> runMe [
	<script>
	^ super runMe
]

{ #category : #specs }
MiQueriesBrowser class >> title [
	^ 'Query Browser'
]

{ #category : #midas }
MiQueriesBrowser >> accept: anObject [
	^ (anObject isKindOf: MooseObject)
		and:
			[ (anObject asMooseGroup allUsing: FamixTNamedEntity) isNotEmpty ]
]

{ #category : #action }
MiQueriesBrowser >> createQueryForTypes: classes [
	| newTypeQuery |
	newTypeQuery := FQTypeQuery new beChildOf: self selectedQuery.
	classes do: [ :aClass | newTypeQuery type: aClass ].
	self updateForQuery: newTypeQuery
]

{ #category : #action }
MiQueriesBrowser >> createTypeQuery [
	self
		createQueryForTypes: (self miSelectedItem collect: #class) copyWithoutDuplicates
]

{ #category : #accessing }
MiQueriesBrowser >> entities [
	^ selectedQuery result
]

{ #category : #midas }
MiQueriesBrowser >> followAction [
	(self accept: toSelect)
		ifFalse: [ ^ self ].
	toSelect := toSelect asMooseGroup allUsing: FamixTNamedEntity.
	queries do: #resetResult.
	self initialQuery result: toSelect.
	self initialQuery name: toSelect first mooseModel name.
	self selectQuery: self initialQuery
]

{ #category : #accessing }
MiQueriesBrowser >> initialQuery [
	^ queries detect: [ :query | query parent isNil ]
]

{ #category : #initialization }
MiQueriesBrowser >> initializePresenters [
	super initializePresenters.
	self initializeQueriesTree.
	self initializeQueryResult.
	self initializeQueryCode.
	self initializeQueriesToolbar
]

{ #category : #initialization }
MiQueriesBrowser >> initializeQueriesToolbar [
	self updateQueryToolbar
]

{ #category : #initialization }
MiQueriesBrowser >> initializeQueriesTree [
	"queriesTree := (SpTreeTablePresenter owner: self)
		addColumn:
			(SpCompositeTableColumn new
				title: 'Queries';
				addColumn: (SpStringTableColumn new evaluated: [ :query | query class label ]));
		roots: {self initialQuery};
		children: #children;
		selectItem: self initialQuery;
		contextMenuFromCommandsGroup: [ self rootCommandsGroup ];
		activateOnDoubleClick;
		whenSelectionChangedDo: [ :selection | self selectQuery: selection selectedItem ];
		whenActivatedDo: [ :selection | self openQueryCreationPresenter ]"

	queriesTree := (MiRoassalQueryPresenter owner: self on: self queries)
		adaptToBrowser: self
]

{ #category : #initialization }
MiQueriesBrowser >> initializeQueryCode [
	queryCode := self newCode text: '"Query code"'
]

{ #category : #initialization }
MiQueriesBrowser >> initializeQueryResult [
	queryResult := (self instantiate: MiResultTreePresenter on: self)
		updateForEntities: self entities;
		yourself
]

{ #category : #midas }
MiQueriesBrowser >> miSelectedItem [
	self
		flag: #FQImprove , 'Moose bug: ifEmpty: returns an OrderedCollection'.
	^ (queryResult miSelectedItem ifEmpty: [ selectedQuery result ])
		asMooseGroup
]

{ #category : #action }
MiQueriesBrowser >> openCombinationPresenterFor: aQuery and: anotherQuery [
	(MiQueriesCombinationPresenter on: self)
		onQueries:
			{aQuery.
			anotherQuery};
		openWithSpec
]

{ #category : #action }
MiQueriesBrowser >> openQueryCreationPresenter [
	(MiQueryCreationPresenter on: self) openWithSpec
]

{ #category : #accessing }
MiQueriesBrowser >> queries [
	^ queries
]

{ #category : #transmissions }
MiQueriesBrowser >> queryInputPort [
	^ MiQueryInputPort newPresenter: self
]

{ #category : #action }
MiQueriesBrowser >> removeQuery: aQuery [
	aQuery children
		ifNotEmpty: [ UIManager default
				alert: 'Cannot remove a query with children for now'.
			^ self ].
	aQuery prepareRemovalFrom: self.
	queries remove: aQuery.
	queriesTree refresh.
	^ aQuery
]

{ #category : #action }
MiQueriesBrowser >> removeSelectedQuery [
	self removeQuery: selectedQuery
]

{ #category : #action }
MiQueriesBrowser >> selectQuery: aQuery [
	selectedQuery := aQuery.
	queriesTree selectItem: selectedQuery.
	queryResult updateForEntities: aQuery result.
	queryCode
		text:
			(aQuery isRootQuery
				ifTrue: [ '"Query code"' ]
				ifFalse: [ EFFormatter
						format:
							(RBParser
								parseExpression: (String streamContents: [ :s | aQuery storeOn: s ])) ]).
	self updateQueryToolbar.
	self update
]

{ #category : #accessing }
MiQueriesBrowser >> selectedQuery [
	^ selectedQuery
]

{ #category : #'accessing model' }
MiQueriesBrowser >> setModelBeforeInitialization: aMooseGroup [
	queries := OrderedCollection new
		add:
			(FQRootQuery new
				result: aMooseGroup;
				yourself);
		yourself.
	selectedQuery := self initialQuery
]

{ #category : #action }
MiQueriesBrowser >> updateForQuery: aQuery [
	"This method is called from FQQueryCreationPresenter and FQQueriesCombinationPresenter. 
	They have the responsibility to establish the [parent* - child] relationship between queries"

	self selectQuery: (queries addLast: aQuery)
]

{ #category : #action }
MiQueriesBrowser >> updateQueryToolbar [
	queriesToolbar := (MiQueryMenuBuilder on: self) newMenuBar
]