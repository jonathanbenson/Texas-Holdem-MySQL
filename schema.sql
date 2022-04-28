DROP DATABASE IF EXISTS HOLDEM;

CREATE DATABASE HOLDEM;

USE HOLDEM;

CREATE TABLE _USER (
    -- An entity to hold the information of a user's account
    
	Username			VARCHAR(255) PRIMARY KEY NOT NULL UNIQUE,
    Pass				VARCHAR(255) NOT NULL,
    Purse				INTEGER NOT NULL CHECK(Purse >= 0)

);



CREATE TABLE _TABLE (
	
    TableId				INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
    SmallBlind			INTEGER NOT NULL CHECK(SmallBlind > 0)

);



CREATE TABLE SEAT (
	
    TableId				INTEGER NOT NULL,
    SitterUsername		VARCHAR(255) DEFAULT NULL,
    _Index				INTEGER NOT NULL,
    
    -- Composite key of TableId and _Index
    -- A seat can be uniquely identified by its table, and position (index) at the table
    PRIMARY KEY(TableId, _Index),
    
    FOREIGN KEY (TableId) REFERENCES _TABLE(TableId),
    FOREIGN KEY (SitterUsername) REFERENCES _USER(Username)
    
);



CREATE TABLE _MATCH (

	MatchId				INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
    WinnerUsername		VARCHAR(255),
    TableId				INTEGER,

    -- Used for server logic
    -- When a new match is created, TMinus is set to a positive integer
    -- ... and a countdown begins to start and initializes the match (insert the first round with blind bets)
    TMinus              INTEGER NOT NULL CHECK(TMinus >= 0),
    
    -- The last match can be NULL (first match of the table)
    LastMatchId			INTEGER,
    
    -- No foreign key constraint for LastMatchId because it can be NULL (first match of table)
    FOREIGN KEY (TableId) REFERENCES _TABLE(TableId)

    -- WinnerUsername can be NULL because an unfinished match can exist without a winner
    
);

CREATE TABLE ROUND (

	RoundId				INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
    MatchId				INTEGER NOT NULL,
    LastRoundId			INTEGER,
    
    -- No foreign key constraint for LastRoundId because it can be NULL (first round of match)
    FOREIGN KEY (MatchId) REFERENCES _MATCH(MatchId)

);

CREATE TABLE PLAY_TYPE (
    -- A PLAY_TYPE is any type of action a user can make during a poker match (blind bets are forced actions)
    -- possibilities: CHECK, FOLD, RAISE, CALL, SMALL_BLIND, BIG_BLIND
	PlayTypeName		VARCHAR(255) PRIMARY KEY NOT NULL UNIQUE
    
);

CREATE TABLE PLAY (
    -- A PLAY is an action a user made during a poker match
    
	PlayId				INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
    PlayerUsername		VARCHAR(255) NOT NULL,
	RoundId				INTEGER NOT NULL,
    LastPlayId			INTEGER,
    PlayType			VARCHAR(255) NOT NULL,
    ChipsNo				INTEGER NOT NULL CHECK(ChipsNo >= 0),

    -- When it is a new players turn, a new play is inserted automatically
    -- A countdown then begins for the player to select their play
    -- ... and if the timer hits zero without a play, the user automatically folds
    TMinus              INTEGER NOT NULL CHECK(TMinus > 0),
    
    -- No foreign key constraint for LastPlayId because it can be NULL (first play of the round)
    FOREIGN KEY (PlayerUsername) REFERENCES _USER(Username),
    FOREIGN KEY (RoundId) REFERENCES ROUND(RoundId),
    FOREIGN KEY (PlayType) REFERENCES PLAY_TYPE(PlayTypeName)

);

CREATE TABLE FACE (
	-- A FACE is a face value of a card: 0-12 (2 is 0, Ace is 12)
    
    Val					INTEGER NOT NULL UNIQUE CHECK(Val >= 0 AND Val <= 12),
    _Name				VARCHAR(30) PRIMARY KEY NOT NULL UNIQUE
    
);

CREATE TABLE SUIT (

	_Name				VARCHAR(30) PRIMARY KEY NOT NULL UNIQUE
    
);

CREATE TABLE CARD (
    -- A CARD is a unique card identifier in a standard deck of 52
    
	Face				VARCHAR(30) NOT NULL,
    Suit				VARCHAR(30) NOT NULL,
    
    PRIMARY KEY (Face, Suit),
    FOREIGN KEY (Face) REFERENCES FACE(_Name),
    FOREIGN KEY (Suit) REFERENCES SUIT(_Name)

);



CREATE TABLE DECK_CARD (

	TableId				INTEGER NOT NULL,
    Face				VARCHAR(30) NOT NULL,
    Suit				VARCHAR(30) NOT NULL,
    _Index              INTEGER,
    
    FOREIGN KEY (TableId) REFERENCES _TABLE(TableId),
    FOREIGN KEY (Face, Suit) REFERENCES CARD(Face, Suit)

);

-- _Index tells the position of the card in the deck
-- and will have to be programatically set when the server boots up
ALTER TABLE DECK_CARD
ADD _Index INTEGER
AFTER Suit;

CREATE TABLE HAND (
    -- A HAND is the two cards a user has during a match
    
	HandId			INTEGER PRIMARY KEY NOT NULL UNIQUE,
    MatchId			INTEGER NOT NULL,
    HolderUsername	VARCHAR(255) NOT NULL,
    
    FOREIGN KEY (MatchId) REFERENCES _MATCH(MatchId),
    FOREIGN KEY (HolderUsername) REFERENCES _USER(Username)

);

CREATE TABLE HAND_CARD (
    -- A HAND_CARD is a single card that is a part of a user's HAND
    
	HandId			INTEGER NOT NULL,
    Face			VARCHAR(30) NOT NULL,
    Suit			VARCHAR(30) NOT NULL,
    
    FOREIGN KEY (HandId) REFERENCES HAND(HandId),
    FOREIGN KEY (Face, Suit) REFERENCES CARD(Face, Suit)
    
);

CREATE TABLE COMMUNITY_CARD (
    -- A COMMUNITY_CARD is a specific card that belongs to a ROUND that has been layed out
    -- ...as a part of a flop, turn, or river

	RoundId			INTEGER NOT NULL,
    Face			VARCHAR(30) NOT NULL,
    Suit			VARCHAR(30) NOT NULL,
    
    -- Each community card belongs to a round
    -- ...and each community card in a round must be unique
    PRIMARY KEY(RoundId, Face, Suit),
    
    FOREIGN KEY (RoundId) REFERENCES ROUND(RoundId),
    FOREIGN KEY (Face, Suit) REFERENCES CARD(Face, Suit)
    
);

CREATE TABLE HAND_TYPE (
    -- A HAND_TYPE is a possible type of card combination
    -- An example would be the ROYAL FLUSH
    -- *NOTE there can be many instances of ROYAL FLUSH...see HAND_TYPE_INSTANCE for more information

	-- Lower number means higher rank
    -- No two hand types can have the same rank
	_Rank			INTEGER PRIMARY KEY NOT NULL,
    
    -- Degree is the number of cards that form the hand type
    -- For example, a PAIR would mean two cards
    -- ...while THREE OF A KIND is three cards
    -- Will be used to check that all the HAND_TYPE_INSTANCEs are valid
    Degree			INTEGER NOT NULL CHECK(Degree >= 1 AND Degree <= 5),
    
    -- examples: ROYAL FLUSH, STRAIGHT, TWO PAIR
    _Name			VARCHAR(255) NOT NULL UNIQUE

);



CREATE TABLE HAND_TYPE_INSTANCE (
    -- A HAND_TYPE_INSTANCE is a specific instance of a HAND_TYPE with defined cards
    -- Example: A possible HAND_TYPE_INSTANCE of the HAND_TYPE "ROYAL FLUSH" would be
    -- ...10 of hearts, jack of hearts, queen of hearts, king of hearts, and ace of hearts
    
	HandTypeInstanceId			INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
    HandTypeRank				INTEGER NOT NULL,
    
    FOREIGN KEY (HandTypeRank) REFERENCES HAND_TYPE(_Rank)
    
);

CREATE TABLE HAND_TYPE_INSTANCE_CARD (
    -- A HAND_TYPE_INSTANCE_CARD is a single card that belongs to a HAND_TYPE_INSTANCE
    
	HandTypeInstanceId			INTEGER NOT NULL,
    Face						VARCHAR(30) NOT NULL,
    Suit						VARCHAR(30) NOT NULL,
    
    FOREIGN KEY (HandTypeInstanceId) REFERENCES HAND_TYPE_INSTANCE(HandTypeInstanceId),
    FOREIGN KEY (Face, Suit) REFERENCES CARD(Face, Suit)

);


-- Below operations are populating the database

-- Initialize the possible user actions in the database
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("CHECK");
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("FOLD");
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("RAISE");
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("CALL");
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("SMALL_BLIND");
INSERT INTO PLAY_TYPE (PlayTypeName) VALUES ("BIG_BLIND");

-- Initialize face values of cards
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

-- Initialize suit values for cards
INSERT INTO SUIT (_Name) VALUES ("SPADES");
INSERT INTO SUIT (_Name) VALUES ("CLUBS");
INSERT INTO SUIT (_Name) VALUES ("DIAMONDS");
INSERT INTO SUIT (_Name) VALUES ("HEARTS");

-- Initialize all card types
INSERT INTO CARD (Face, Suit)
SELECT FACE._Name, SUIT._Name
FROM FACE, SUIT;

-- Source: https://www.cardplayer.com/rules-of-poker/hand-rankings
-- Initialize all of the possible hand types
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



-- Initialize all possible hand type instances
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
