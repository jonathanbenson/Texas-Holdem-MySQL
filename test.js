
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


	test('NEW_TABLE stored procedure', () => {

		return query(`

			CALL NEW_TABLE(25);

		`).then(() => query(`

			SELECT TableId as id, SmallBlind as smallBlind FROM _TABLE;

		`)).then(result => {
			/*

			Upon the creation of a new table, there should be a new record in the _TABLE table
			with a small blind and table id.

			*/

			let table = result[0];

			expect(table.id).toEqual(1);
			expect(table.smallBlind).toEqual(25);

		}).then(() => query(`

			SELECT Face as face, Suit as suit, _Index as i
			FROM DECK_CARD
			WHERE TableId = 1
			ORDER BY _Index;

		`)).then(result => {
			/*

			There should also be 52 newly created records in the DECK_CARD table
			that represents the deck of cards of that table.

			Each deck card should have an index that tells its place in the deck.

			*/

			let expectedDeckCards = [
				 { face: '2', suit: 'SPADES', i: 1 },
				 { face: '2', suit: 'HEARTS', i: 2 },
				 { face: '2', suit: 'DIAMONDS', i: 3 },
				 { face: '2', suit: 'CLUBS', i: 4 },
				 { face: '3', suit: 'SPADES', i: 5 },
				 { face: '3', suit: 'HEARTS', i: 6 },
				 { face: '3', suit: 'DIAMONDS', i: 7 },
				 { face: '3', suit: 'CLUBS', i: 8 },
				 { face: '4', suit: 'SPADES', i: 9 },
				 { face: '4', suit: 'HEARTS', i: 10 },
				 { face: '4', suit: 'DIAMONDS', i: 11 },
				 { face: '4', suit: 'CLUBS', i: 12 },
				 { face: '5', suit: 'SPADES', i: 13 },
				 { face: '5', suit: 'HEARTS', i: 14 },
				 { face: '5', suit: 'DIAMONDS', i: 15 },
				 { face: '5', suit: 'CLUBS', i: 16 },
				 { face: '6', suit: 'SPADES', i: 17 },
				 { face: '6', suit: 'HEARTS', i: 18 },
				 { face: '6', suit: 'DIAMONDS', i: 19 },
				 { face: '6', suit: 'CLUBS', i: 20 },
				 { face: '7', suit: 'SPADES', i: 21 },
				 { face: '7', suit: 'HEARTS', i: 22 },
				 { face: '7', suit: 'DIAMONDS', i: 23 },
				 { face: '7', suit: 'CLUBS', i: 24 },
				 { face: '8', suit: 'SPADES', i: 25 },
				 { face: '8', suit: 'HEARTS', i: 26 },
				 { face: '8', suit: 'DIAMONDS', i: 27 },
				 { face: '8', suit: 'CLUBS', i: 28 },
				 { face: '9', suit: 'SPADES', i: 29 },
				 { face: '9', suit: 'HEARTS', i: 30 },
				 { face: '9', suit: 'DIAMONDS', i: 31 },
				 { face: '9', suit: 'CLUBS', i: 32 },
				 { face: '10', suit: 'SPADES', i: 33 },
				 { face: '10', suit: 'HEARTS', i: 34 },
				 { face: '10', suit: 'DIAMONDS', i: 35 },
				 { face: '10', suit: 'CLUBS', i: 36 },
				 { face: 'JACK', suit: 'SPADES', i: 37 },
				 { face: 'JACK', suit: 'HEARTS', i: 38 },
				 { face: 'JACK', suit: 'DIAMONDS', i: 39 },
				 { face: 'JACK', suit: 'CLUBS', i: 40 },
				 { face: 'QUEEN', suit: 'SPADES', i: 41 },
				 { face: 'QUEEN', suit: 'HEARTS', i: 42 },
				 { face: 'QUEEN', suit: 'DIAMONDS', i: 43 },
				 { face: 'QUEEN', suit: 'CLUBS', i: 44 },
				 { face: 'KING', suit: 'SPADES', i: 45 },
				 { face: 'KING', suit: 'HEARTS', i: 46 },
				 { face: 'KING', suit: 'DIAMONDS', i: 47 },
				 { face: 'KING', suit: 'CLUBS', i: 48 },
				 { face: 'ACE', suit: 'SPADES', i: 49 },
				 { face: 'ACE', suit: 'HEARTS', i: 50 },
				 { face: 'ACE', suit: 'DIAMONDS', i: 51 },
				 { face: 'ACE', suit: 'CLUBS', i: 52 }
			  ];

			expect(result).toEqual(expectedDeckCards);

		}).then(() => query(`

			SELECT SitterUsername as player, _Index as i
			FROM SEAT
			WHERE TableId=1;

		`)).then(result => {
			/*

			There should also be 10 newly created empty seats for the
			newly created table.

			*/

			let expectedSeats = [
				 { player: null, i: 0 },
				 { player: null, i: 1 },
				 { player: null, i: 2 },
				 { player: null, i: 3 },
				 { player: null, i: 4 },
				 { player: null, i: 5 },
				 { player: null, i: 6 },
				 { player: null, i: 7 },
				 { player: null, i: 8 },
				 { player: null, i: 9 }
			  ];

			expect(result).toEqual(expectedSeats);


		});


	});

});



