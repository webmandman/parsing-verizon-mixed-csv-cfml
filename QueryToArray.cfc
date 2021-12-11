<cfcomponent hint="Common query helper">

	<!--- From Ben Nadel --->
	<cffunction name="convert" access="public" returntype="array" output="false"
		hint="This turns a query into an array of structures.">

		<!--- Define arguments. --->
		<cfargument name="Data" type="query" required="yes" />

		<!---[RK] Added Case and ColumnList to overridde ColdFusions default
		UPPERCASE conversion of keys/column names --->
		<cfargument name="Case" type="string" required="no" default="uppercase" />
		<cfargument name="ColumnList" type="string" required="no" hint="Overrides the column list with provided list." default=""/>

		<cfscript>

			// Define the local scope.
			var LOCAL = StructNew();

			// Get the column names as an array.
			if(ListLen(ARGUMENTS.ColumnList)){
				LOCAL.Columns = ListToArray(ARGUMENTS.ColumnList);
			}else{
				LOCAL.Columns = ListToArray( ARGUMENTS.Data.ColumnList );
			}
			

			// Create an array that will hold the query equivalent.
			LOCAL.QueryArray = ArrayNew( 1 );

			// Loop over the query.
			for (LOCAL.RowIndex = 1 ; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){

				// Create a row structure.
				LOCAL.Row = StructNew();

				// Loop over the columns in this row.
				for (LOCAL.ColumnIndex = 1 ; LOCAL.ColumnIndex LTE ArrayLen( LOCAL.Columns ) ; LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)){

					// Get a reference to the query column.
					LOCAL.ColumnName = LOCAL.Columns[ LOCAL.ColumnIndex ];

					if(ARGUMENTS.Case EQ 'lowercase'){
						// Store the query cell value into the struct by key using lowercase for key
						LOCAL.Row[ lcase(LOCAL.ColumnName) ] = ARGUMENTS.Data[ LOCAL.ColumnName ][ LOCAL.RowIndex ];
					}else{
						// Store the query cell value into the struct by key.
						LOCAL.Row[ "#LOCAL.ColumnName#" ] = ARGUMENTS.Data[ LOCAL.ColumnName ][ LOCAL.RowIndex ];
					}
					

				}

				// Add the structure to the query array.
				ArrayAppend( LOCAL.QueryArray, LOCAL.Row );

			}

			// Return the array equivalent.
			return( LOCAL.QueryArray );

		</cfscript>
	</cffunction>
</cfcomponent>