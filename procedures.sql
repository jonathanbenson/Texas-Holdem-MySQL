-- used for testing
DELIMITER //

CREATE PROCEDURE CLEAN ()
BEGIN

    DELETE FROM ROUND;
    DELETE FROM _MATCH;

    UPDATE SEAT
    SET SitterUsername=NULL;

    UPDATE _TABLE
    SET TableState=0;

    ALTER TABLE _MATCH
    AUTO_INCREMENT = 1;

    ALTER TABLE ROUND
    AUTO_INCREMENT = 1;

END; //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE INIT_USERS ()
BEGIN

	-- Inserting accounts for each person in our group
	-- Username = first and last initials (lowercase)
	-- Password = Username + "123"
	INSERT INTO _USER (Username, Pass, Purse) VALUES ("bob", "bob123", 1000);
	INSERT INTO _USER (Username, Pass, Purse) VALUES ("sally", "sally123", 1000);
	INSERT INTO _USER (Username, Pass, Purse) VALUES ("joe", "joe123", 1000);
	INSERT INTO _USER (Username, Pass, Purse) VALUES ("chris", "chris123", 1000);
	INSERT INTO _USER (Username, Pass, Purse) VALUES ("jane", "jane123", 1000);

END; //

DELIMITER ;




DELIMITER //

CREATE PROCEDURE INIT_TABLES ()
BEGIN

	-- Inserting 3 tables with small blinds of 25, 50, and 100
	-- On the user's end, they will be named Table #{TableId}
	INSERT INTO _TABLE (TableId, SmallBlind, TableState) VALUES (1, 25, 0);
	INSERT INTO _TABLE (TableId, SmallBlind, TableState) VALUES (2, 50, 0);
	INSERT INTO _TABLE (TableId, SmallBlind, TableState) VALUES (3, 100, 0);

	-- Initialize the 10 seats for Table #1
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 0);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 1);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 2);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 3);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 4);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 5);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 6);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 7);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 8);
	INSERT INTO SEAT (TableId, _Index) VALUES (1, 9);

	-- Initialize the 10 seats for Table #2
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 0);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 1);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 2);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 3);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 4);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 5);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 6);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 7);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 8);
	INSERT INTO SEAT (TableId, _Index) VALUES (2, 9);

	-- Initialize the 10 seats for Table #3
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 0);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 1);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 2);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 3);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 4);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 5);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 6);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 7);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 8);
	INSERT INTO SEAT (TableId, _Index) VALUES (3, 9);

END; //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE INIT_PLAY_TYPES ()
BEGIN

	-- Initialize the possible user actions in the database
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("CHECK");
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("FOLD");
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("RAISE");
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("CALL");
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("SMALL_BLIND");
	INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("BIG_BLIND");

END; //

DELIMITER ;






DELIMITER //

CREATE PROCEDURE INIT_CARDS ()
BEGIN

	INSERT INTO FACE (Val, _Name) VALUES (0, "2");
	INSERT INTO FACE (Val, _Name) VALUES (1, "3");
	INSERT INTO FACE (Val, _Name) VALUES (2, "4");
	INSERT INTO FACE (Val, _Name) VALUES (3, "5");
	INSERT INTO FACE (Val, _Name) VALUES (4, "6");
	INSERT INTO FACE (Val, _Name) VALUES (5, "7");
	INSERT INTO FACE (Val, _Name) VALUES (6, "8");
	INSERT INTO FACE (Val, _Name) VALUES (7, "9");
	INSERT INTO FACE (Val, _Name) VALUES (8, "10");
	INSERT INTO FACE (Val, _Name) VALUES (9, "JACK");
	INSERT INTO FACE (Val, _Name) VALUES (10, "QUEEN");
	INSERT INTO FACE (Val, _Name) VALUES (11, "KING");
	INSERT INTO FACE (Val, _Name) VALUES (12, "ACE");

	INSERT INTO SUIT (_Name) VALUES ("SPADES");
	INSERT INTO SUIT (_Name) VALUES ("CLUBS");
	INSERT INTO SUIT (_Name) VALUES ("DIAMONDS");
	INSERT INTO SUIT (_Name) VALUES ("HEARTS");

	INSERT INTO CARD (Face, Suit)
	SELECT FACE._Name, SUIT._Name
	FROM FACE, SUIT;

END; //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE INIT_DECKS ()
BEGIN

	-- Initialize each of the table's decks
	INSERT INTO DECK_CARD
	SELECT TableId, Face, Suit
	FROM _TABLE, CARD;

END; //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE INIT_HAND_TYPES ()
BEGIN

	-- Source: https://www.cardplayer.com/rules-of-poker/hand-rankings
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (1, 5, "ROYAL FLUSH");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (2, 5, "STRAIGHT FLUSH");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (3, 4, "FOUR OF A KIND");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (4, 5, "FULL HOUSE");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (5, 5, "FLUSH");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (6, 5, "STRAIGHT");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (7, 3, "THREE OF A KIND");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (8, 4, "TWO PAIR");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (9, 2, "PAIR");
	INSERT INTO HAND_TYPE (_Rank, Degree, _Name) VALUES (10, 1, "HIGH CARD");

END; //

DELIMITER ;



DELIMITER //

CREATE PROCEDURE INIT_HAND_TYPE_INSTANCES ()
BEGIN

	-- Example of initializing the instances of ROYAL FLUSH:

	INSERT INTO HAND_TYPE_INSTANCE (HandTypeRank) VALUES (1);

	SET @latestHandTypeInstanceId = (SELECT MAX(HandTypeInstanceId) FROM HAND_TYPE_INSTANCE);

	-- Royal flush of SPADES
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "10", "SPADES");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "JACK", "SPADES");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "QUEEN", "SPADES");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "KING", "SPADES");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "ACE", "SPADES");

	INSERT INTO HAND_TYPE_INSTANCE (HandTypeRank) VALUES (1);

	SET @latestHandTypeInstanceId = (SELECT MAX(HandTypeInstanceId) FROM HAND_TYPE_INSTANCE);

	-- Royal flush of CLUBS
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "10", "CLUBS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "JACK", "CLUBS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "QUEEN", "CLUBS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "KING", "CLUBS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "ACE", "CLUBS");

	INSERT INTO HAND_TYPE_INSTANCE (HandTypeRank) VALUES (1);

	SET @latestHandTypeInstanceId = (SELECT MAX(HandTypeInstanceId) FROM HAND_TYPE_INSTANCE);

	-- Royal flush of DIAMONDS
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "10", "DIAMONDS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "JACK", "DIAMONDS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "QUEEN", "DIAMONDS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "KING", "DIAMONDS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "ACE", "DIAMONDS");

	INSERT INTO HAND_TYPE_INSTANCE (HandTypeRank) VALUES (1);

	SET @latestHandTypeInstanceId = (SELECT MAX(HandTypeInstanceId) FROM HAND_TYPE_INSTANCE);

	-- Royal flush of HEARTS
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "10", "HEARTS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "JACK", "HEARTS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "QUEEN", "HEARTS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "KING", "HEARTS");
	INSERT INTO HAND_TYPE_INSTANCE_CARD (HandTypeInstanceId, Face, Suit) VALUES (@latestHandTypeInstanceId, "ACE", "HEARTS");

END; //

DELIMITER ;
