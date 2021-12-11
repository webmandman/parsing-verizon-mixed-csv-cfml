component accessors=true {
	property numeric accountNo;
	property string statementDate;
	property array accounts;
	property string chargetypes;
	
	function test(){
		var str = "555-666.23";
		var str2 = "888-777.11";
		if( str == str2 ) print.line( str );
	}

	function parse(required string filepath) {
		/*  
		 * Get fully qualified path. filepath can be relative.
		 * A more efficient and performant resolver(commandbox style)
		*/
		var fqpath = fileSystemUtil.resolvePath( filepath );

		/*  
		 * filepath must be absolute path
		*/
		//var fqpath = filepath;
		
		/*  
		 * read csv and convert to array of lines
		*/
		var csvlines = fileRead( fqpath ).listToArray(chr(13) & chr(10));
		/*  
		 * Set account no, date, chargetypes(hardcoded), and account charges
		*/
		setAccountNo(csvlines[1].listToArray()[2]);
		setStatementDate( parseDateTime( csvlines[2].listToArray()[2] ) );
		var ctypes = "account,monthly,usage,equipment,surcharges,tax,3rd";
		setChargetypes(ctypes);
		
		/*
		 * Get users into one clean array
		 */
		var users = getUsers( csvlines );

		/*
		 * Group all users by cost center.
		 * BUT only process the valid users list.
		 */
		setAccounts( groupByCostCenter( users[1] ) );
		
	}

	array function getUsers(required array csvlines){
		/*  
		 * util.CSVToQuery handles comma delimeter and commas in fields
		 * otherwise, parsing a column value that contains a comma ie: $1,2900
		 * can be painful to handle
		*/
		var util = new util();
		var queryToArray = new queryToArray();
		
		var users = [[],[]];
		
		/*
		 * LOOP through every line which includes subtotal lines and header lines,
		 * but ONLY process cost center lines which are the charges for each user.
		 * MERGE all users that are part of the same cost center.
		 */
		for( lstring in csvlines ){
			/* 
			 * Current line is a list that includes acc no, user, all charges and total
			 * CONVERT the current csv line into an array.
			*/
			var larray = queryToArray.convert(data=util.CSVToQuery( lstring ))[1];
			
			// Cost Center
			var acc = larray.COLUMN_1;

			/* 
			 * ONLY process lines that start with a cost center number
			 * The number format is: ddd-ddd.dd
			 * Some numbers do not use a dash or period
			 * This regex also finds those numbers that do not
			 * have a (-) dash or (.) period.
			 * Regex: (3 or 4 numbers)(- or space)(3 numbers)(. or space)(2 numbers)
			*/

			if( isValidCostCenter(acc) ){
				// append to array
				users[1].append( larray );
			}else {
				// remove non-alphanumerics
				acc = REReplace(acc,"[^0-9A-Za-z ]","","all");
				acc = reReplace(acc,"[[:space:]]", "", "ALL");

				/*
				 * ONLY if the value is numeric and is a valid cost center number
				 * then add it to the valid users list "users[1]"
				 * invalid users list is "users[2]"
				 */
				if( isNumeric(acc) ){
					// convert the numeric value into the cost center format
					acc = insert('.', acc, acc.len()-2);
					acc = insert('-', acc, acc.len()-6);

					if( isValidCostCenter(acc) ){
						// add to valid users list
						users[1].append( larray );
					}else{
						// into the invalid list you go
						users[2].append( larray );
					}
				// the only other KNOWN invalid value
				}else if( acc == "NoCostCenter" ){
					// add to invalid list
					users[2].append( larray );
				}
			}
		}
		return users;
	}
	
	boolean function isValidCostCenter(required string acc){
		if( refind( "[0-9]{3,4}[-/ ][0-9]{3}[. ][0-9]{2}", acc ) ) return true;
		return false;
	}

	array function groupByCostCenter(required array users){
		/***
		 * Create a new collection called Accounts.
		 * Accounts is an array of cost centers.
		 * Each cost center is struct with a users array, 
		 * and the cost center account number.
		 * { 
		 *		users: [ {
		 *			user,
		 *			charges: [], 
		 *			total } ] 
		 *		costcenter 
		 * }
		***/
		var accounts = [];
		var costcenter = {};
		
		/*
		 * LOOP through every line which includes subtotal lines and header lines,
		 * but ONLY process cost center lines which are the charges for each user.
		 * MERGE all users that are part of the same cost center.
		 */
		var i = 1;
		for( user in users.mid(1,5) ){
			/*
			 * Determine if we're about to process a different cost center.
			 * Cost center charges are grouped, so they should come in order. 
			 * On every new cost center line RESET the account struct 
			*/
			print.line("before resetting")
			print.line(costcenter);
			if( i == 1 ){
				costcenter = {};
				costcenter["costcenter"] = user.COLUMN_1;
				costcenter["users"] = [];
				print.line("after resetting")
				print.line(costcenter);
			}else if( user.COLUMN_1 neq users[i-1].COLUMN_1 ){
				costcenter = {};
				costcenter["costcenter"] = user.COLUMN_1;
				costcenter["users"] = [];
				print.line("after resetting")
				print.line(costcenter);
			}

			/*
			 * Save the username "phonenumber and full name"
			 * Save the total of all charges
			 */
			var user_data = { 
				"user": user.COLUMN_2,
				 "total": user.COLUMN_10,
				 "charges": []
			};

			/* 
			 * LOOP through the 7 different charge types and add to charges array.
			 * Start at index 3 because 1 is cc no and 2 is username.
			*/
			var j = 3;
			for( t in getChargetypes().listToArray() ){
				var charge =  { "#t#": user["COLUMN_#j#"] }; 
				user_data.charges.append( charge );
				j += 1;
			}
			
			/*
			 * Save each user into the cost center
			 */
			costcenter.users.append( user_data );

			print.line("after saving")
			print.line(costcenter);
			
			/*
			 * When you reach the last user in the cost center append to accounts
			 */
			if( i < users.len() && user.COLUMN_1 neq users[i+1].COLUMN_1 ){
				accounts.append( costcenter );
			// append the very last one
			}else if( i == users.len() ){
				accounts.append( costcenter );
			}
			
			/*
			 * Set the previous cost center
			 */
			i += 1;
		}
		return accounts;
	}

	array function getMemento(){
		var props = getMetadata(this).properties;
		var memento = []
		for( prop in props ){
			memento.append({"#prop["name"]#":#variables[prop["name"]]#});
		}
		return memento;
	}
}
