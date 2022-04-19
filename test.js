
var mysql = require("mysql");

function createConnection() {
	/*
	
	Creates a connection to the database.
	Assumes there is a user with name 'root' and password 'password'
	Assumes the database is called 'HOLDEM' (same as our init.sql file)
	*/
	return mysql.createConnection({
 
	   host: "localhost",
	   user: "root",
	   password: "password",
	   database: "HOLDEM"
	
	});
 
 }


function cleanDatabase() {
	/*

	Cleans the database after each test.

	*/

	return new Promise((resolve, reject) => {

		let connection = createConnection();

		connection.connect();

		connection.query(
			`CALL CLEAN ()`,

			function(error, results, fields) {

				connection.end();

				if (error) return reject(error);

				return resolve(true);

			});

		});

}


describe("database procedure tests", () => {

	// before all tests and after each test clean the database
	beforeAll(() => { return cleanDatabase(); });
	afterEach(() => { return cleanDatabase(); });

	test("example test", () => {

		expect(true).toEqual(true);

	});

});



