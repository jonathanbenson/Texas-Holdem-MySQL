
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

		Insert 4 players. 1 has #chips in their purse below the buy-in of the table (buy-in is x4 the small blind).
		Insert 1 table.
		Insert 2 EMPTY seats into that table.

		*** We are only using a table with 2 seats in this test for convenience.
		*** In the real thing, the NEW_TABLE procedure would be used to create a table with 10 seats.

		*/

		return query(`

			INSERT INTO _USER (Username, Pass, Purse) VALUES ("jonathan", "password", 150);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("kevin", "password", 150);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("joshua", "password", 150);

			INSERT INTO _USER (Username, Pass, Purse) VALUES ("rainman", "password", 25);		
			
			INSERT INTO _TABLE (SmallBlind) VALUES (25);
			
			INSERT INTO SEAT (TableId, _Index) VALUES (1, 0);
			INSERT INTO SEAT (TableId, _Index) VALUES (1, 1);

		`).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("invalid username", 1, @message);
			
			SELECT @message AS message;

			SELECT SitterUsername AS player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let 1 player with an invalid username try to join the table.

			The procedure should return a message FAIL - USER NOT FOUND.

			There should be no changes to the database.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('FAIL - USER NOT FOUND');


			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toBeNull();
			expect(player2).toBeNull();

		}).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("rainman", 1, @message);
			
			SELECT @message AS message;

			SELECT SitterUsername AS player
			FROM SEAT
			WHERE TableId=1
			ORDER BY SEAT._Index ASC;

		`)).then(result => {
			/*

			Let 1 player with an insufficient amount of chips in their purse try an join the table.

			The procedure should return a message FAIL - NOT ENOUGH FUNDS.

			There should be no changes to the database.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('FAIL - NOT ENOUGH FUNDS');


			let player1 = result[3][0].player;
			let player2 = result[3][1].player;

			expect(player1).toBeNull();
			expect(player2).toBeNull();

		}).then(() => query(`

				SET @message = "hello";

				CALL JOIN_TABLE ("jonathan", 1, @message);
				
				SELECT @message AS message;

				SELECT SitterUsername AS player
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
			
			SELECT @message AS message;

			SELECT SitterUsername AS player
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
			
			SELECT @message AS message;

			SELECT SitterUsername AS player
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
			
			SELECT @message AS message;

			SELECT SitterUsername AS player
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
  
  test("LEAVE_TABLE stored procedure", () => {

		return query(`

		INSERT INTO _USER (Username, Pass, Purse) VALUES ("jonathan", "password", 100);
			
		INSERT INTO _TABLE (SmallBlind) VALUES (25);
		
		INSERT INTO SEAT (TableId, _Index) VALUES (1, 0);
		INSERT INTO SEAT (TableId, _Index) VALUES (1, 1);

		`).then(() => query(`

		SET @message = "hello";

		CALL JOIN_TABLE ("jonathan", 1, @message);

		CALL LEAVE_TABLE ("jonathan", @message);
		
		SELECT @message as message;

		SELECT SitterUsername as player
		FROM SEAT
		WHERE TableId=1;

		`)).then(result => {
			/*
			Let 1 player join the table.

			Remove that player.

			Procedure should return message of SUCCESS.

			Table should be empty.
			*/
			let message = result[3][0].message;

			expect(message).toEqual('SUCCESS');

			let player1 = result[4][0].player;
			let player2 = result[4][1].player;

			expect(player1).toEqual(null);
			expect(player2).toEqual(null);

		}).then(() => query(`
		SET @message = "hello";

		CALL LEAVE_TABLE("jonathan", @message);

		SELECT @message as message;
		`).then(result => {
			/*
			Try to remove a player that is not at a table.

			Procedure should return message of FAIL - USER IS NOT AT A TABLE.
			*/
			let message = result[2][0].message;

			expect(message).toEqual('FAIL - USER IS NOT AT A TABLE')
		})).then(() => query(`
		SET @message = "hello";

		CALL LEAVE_TABLE("toby", @message);

		SELECT @message as message;
		`)).then(result => {
			/*
			Try to remove a player that does not exist.

			Procedure should return message of FAIL - USER NOT FOUND.
			*/
			let message = result[2][0].message;

			expect(message).toEqual('FAIL - USER NOT FOUND')
		});
	});

	test("GET_EMPTY_TABLE_SEAT stored procedure", () => {

		return query(`

		INSERT INTO _USER (Username, Pass, Purse) VALUES ("jonathan", "password", 100);
			
		INSERT INTO _TABLE (SmallBlind) VALUES (25);
		
		INSERT INTO SEAT (TableId, _Index) VALUES (1, 0);
		INSERT INTO SEAT (TableId, _Index) VALUES (1, 1);

		`).then(() => query(`

		SET @message = "hello";

		CALL JOIN_TABLE("jonathan", 1, @message);

		CALL GET_EMPTY_TABLE_SEAT(@message);
		
		SELECT @message as message;

		SELECT * FROM SEAT;
		SELECT * FROM SEAT WHERE SitterUsername IS NULL;
		`)).then(result => {
			/*
			Let 1 player join the table.

			Look for empty table.

			Procedure should return message of 1.

			Table should be empty.
			*/

			let message = result[3][0].message;

			expect(message).toEqual(1);
		});
	});


	test('NEW_TABLE stored procedure', () => {

		/*

		Setup test:

		Create a new table.

		*/

		return query(`

			CALL NEW_TABLE(25);

		`).then(() => query(`

			SELECT TableId AS id, SmallBlind AS smallBlind FROM _TABLE;

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

			SELECT SitterUsername AS player, _Index as i
			FROM SEAT
			WHERE TableId=1
			ORDER BY _Index ASC;

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


	test("NEW_MATCH stored procedure", () => {
		/*

		Setup test:

		Create 5 new users.
		Create 1 new table.

		*/

		return query(`

			INSERT INTO _USER (Username, Pass, Purse) VALUES ("jonathan", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("kevin", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("joshua", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("jacob", "password", 100);
			INSERT INTO _USER (Username, Pass, Purse) VALUES ("thomas", "password", 100);
			
			CALL NEW_TABLE (25);

		`).then(() => query(`

			SET @message = "hello";

			CALL NEW_MATCH (1, @message);

			SELECT @message AS message;

		`)).then(result => {
			/*

			Try to create a match when there are less than 4 players sitting at the table.

			The procedure should return a message FAIL - NOT ENOUGH PLAYERS.

			There should be no changes to the database.

			*/

			let message = result[2][0].message;

			expect(message).toEqual('FAIL - NOT ENOUGH PLAYERS');

		}).then(() => query(`

			SET @message = "hello";

			CALL JOIN_TABLE ("jonathan", 1, @message);
			CALL JOIN_TABLE ("kevin", 1, @message);
			CALL JOIN_TABLE ("joshua", 1, @message);
			CALL JOIN_TABLE ("jacob", 1, @message);
			CALL JOIN_TABLE ("thomas", 1, @message);

			CALL NEW_MATCH (1, @message);

			SELECT @message as message;

			SELECT MatchId AS latestMatchId, LastMatchId AS lastMatchId
			FROM _MATCH
			WHERE TableId = 1
			ORDER BY MatchId DESC
			LIMIT 1;

		`)).then(result => {
			/*

			Let 4 players sit at the table and then create the first match of the table.

			A new match should be created since there are at least 4 players sitting at the table.
			... the new match should have an id of 1, and a last match id of null (since it is the first one)

			The procedure should return a message SUCCESS.
			

			*/

			let message = result[7][0].message;

			let latestMatchId = result[8][0].latestMatchId;
			let lastMatchId = result[8][0].lastMatchId;

			expect(message).toEqual('SUCCESS');

			expect(latestMatchId).toEqual(1);
			expect(lastMatchId).toBeNull();

		}).then(() => query(`

			SET @message = "hello";

			CALL NEW_MATCH (1, @message);

			SELECT @message AS message;

			SELECT MatchId AS latestMatchId, LastMatchId AS lastMatchId
			FROM _MATCH
			WHERE TableId = 1
			ORDER BY MatchId DESC
			LIMIT 1;

		`)).then(result => {

			/*

			Create a second match for the table.

			This time we expect the new match's last match id to be 1 (instead of null)
			because it is not the first match.

			Its own match id will be 2 because it is the second match created.

			*/

			let message = result[2][0].message;

			let latestMatchId = result[3][0].latestMatchId;
			let lastMatchId = result[3][0].lastMatchId;

			expect(message).toEqual('SUCCESS');

			expect(latestMatchId).toEqual(2);
			expect(lastMatchId).toEqual(1);

		});

	});


	test("SHUFFLE_DECK stored procedure", () => {
		/*

		Setup test:

		Create a new table which initializes an un-shuffled deck of cards.
		Shuffle the newly created deck of cards.

		*/

		return query(`

			CALL NEW_TABLE (25);

			CALL SHUFFLE_DECK (1);

			SELECT Face AS face, Suit AS suit
			FROM DECK_CARD
			WHERE TableId = 1
			ORDER BY CONCAT(Face, '-', Suit);

			SELECT _Index AS i
			FROM DECK_CARD
			WHERE TableId = 1;

		`).then(result => {
			/*

			Upon shuffling a deck of cards, the indices of the deck cards should
			be randomly swapped with each other 104 times.

			To test this we expect that the following conditions are met:
			1. The shuffled indices contain indices 1-52, no repeats.
			2. The shuffles indices are not sorted (due to extremely low probability).

			*/

			let expectedSortedIndices = [
				 { i: 1 },   { i: 2 },
				 { i: 3 },   { i: 4 },
				 { i: 5 },   { i: 6 },
				 { i: 7 },   { i: 8 },
				 { i: 9 },   { i: 10 },
				 { i: 11 },  { i: 12 },
				 { i: 13 },  { i: 14 },
				 { i: 15 },  { i: 16 },
				 { i: 17 },  { i: 18 },
				 { i: 19 },  { i: 20 },
				 { i: 21 },  { i: 22 },
				 { i: 23 },  { i: 24 },
				 { i: 25 },  { i: 26 },
				 { i: 27 },  { i: 28 },
				 { i: 29 },  { i: 30 },
				 { i: 31 },  { i: 32 },
				 { i: 33 },  { i: 34 },
				 { i: 35 },  { i: 36 },
				 { i: 37 },  { i: 38 },
				 { i: 39 },  { i: 40 },
				 { i: 41 },  { i: 42 },
				 { i: 43 },  { i: 44 },
				 { i: 45 },  { i: 46 },
				 { i: 47 },  { i: 48 },
				 { i: 49 },  { i: 50 },
				 { i: 51 },  { i: 52 }
			  ];

			let indices = JSON.parse(JSON.stringify(result[3]));
			let sortedIndices = result[3].sort((a, b) => a.i - b.i);

			expect(indices).not.toEqual(sortedIndices);
			expect(sortedIndices).toEqual(expectedSortedIndices);

		});

	});

});



