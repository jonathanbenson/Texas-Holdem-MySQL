
var mysql = require("mysql");


function query(text) {
	/*

	Queries the database. Returns any rows that are retrieved from a SELECT statement.

	*/

	return new Promise((resolve, reject) => {

		let connection = mysql.createConnection({
 
			host: "localhost",
			user: "root",
			password: "password",
			database: "HOLDEM"
		 
		});

		connection.connect();

		connection.query(
			text,

			function(error, results, fields) {

				connection.end();

				if (error) return reject(error);

				return resolve(results);

			});

		});

}


describe("database procedure tests", () => {

	// before all tests and after each test clean the database
	beforeAll(() => { return query("CALL CLEAN ()"); });
	afterEach(() => { return query("CALL CLEAN ()"); });

	test("example test", () => {

		expect(true).toEqual(true);

	});

});



