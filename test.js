
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
			database: "HOLDEM",
			multipleStatements: true
		 
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

	test("JOIN_TABLE stored procedure", () => {

		/*

		Setup test:

		Insert 3 players.
		Insert 1 table.
		Insert 2 EMPTY seats into that table.

		*/

		return query(`

			INSERT INTO _USER (Username, Pass, Purse) VALUES ("jonathan", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("kevin", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("joshua", "password", 100);
			
			INSERT INTO _TABLE (SmallBlind) VALUES (25);
			
			INSERT INTO SEAT (TableId, _Index) VALUES (1, 0);
			INSERT INTO SEAT (TableId, _Index) VALUES (1, 1);

		`).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("jonathan", 1, @message);
			
			SELECT @message as message;

			SELECT SitterUsername as player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let 1 player join the table.

			Procedure should return message of SUCCESS.

			User should be sitting at the table.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('SUCCESS');


			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toEqual("jonathan");
			expect(player2).toBeNull();

		}).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("jonathan", 1, @message);
			
			SELECT @message as message;

			SELECT SitterUsername as player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let 1 player try to join the table when they are already sitting at the table.

			Procedure should return message of FAIL - PLAYER ALREADY AT TABLE.

			Nothing should change in the database.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('FAIL - PLAYER ALREADY AT TABLE');

			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toEqual("jonathan");
			expect(player2).toBeNull();

		}).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("kevin", 1, @message);
			
			SELECT @message as message;

			SELECT SitterUsername as player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let a 2nd player join the table.

			Procedure should return message of SUCCESS because 2 players can join the table.

			User should be sitting at the table.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('SUCCESS');


			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toEqual("jonathan");
			expect(player2).toEqual("kevin");

		}).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("joshua", 1, @message);
			
			SELECT @message as message;

			SELECT SitterUsername as player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let a 3rd player try to join the table

			Procedure should return message of FAIL - NO EMPTY SEATS.

			Database should not change.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('FAIL - NO EMPTY SEATS');


			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toEqual("jonathan");
			expect(player2).toEqual("kevin");

		});

	});

});



