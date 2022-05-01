-- used for testing

DROP PROCEDURE IF EXISTS CLEAN;

DELIMITER //

CREATE PROCEDURE CLEAN ()
BEGIN
    /*

    Cleans out the database in between each test.

    */

    SET FOREIGN_KEY_CHECKS = 0;

    DELETE FROM DECK_CARD;
    DELETE FROM SEAT;
    DELETE FROM ROUND;
    DELETE FROM _MATCH;
    DELETE FROM _TABLE;
    DELETE FROM _USER;

    UPDATE SEAT
    SET SitterUsername=NULL;

    ALTER TABLE _MATCH
    AUTO_INCREMENT = 1;

    ALTER TABLE _TABLE
    AUTO_INCREMENT = 1;

    ALTER TABLE ROUND
    AUTO_INCREMENT = 1;

    SET FOREIGN_KEY_CHECKS = 1;

END; //

DELIMITER ;



-- Insert the cards into the deck

/* INSERT INTO DECK_CARD (Face, Suit) VALUES

('A', 'Clubs'),
('A', 'Diamonds'),
('A', 'Hearts'),
('A', 'Spades'),

('Two', 'Clubs'),
('Two', 'Diamonds'),
('Two', 'Hearts'),
('Two', 'Spades'),

('Three', 'Clubs'),
('Three', 'Diamonds'),
('Three', 'Hearts'),
('Three', 'Spades'),

('Four', 'Clubs'),
('Four', 'Diamonds'),
('Four', 'Hearts'),
('Four', 'Spades'),

('Five', 'Clubs'),
('Five', 'Diamonds'),
('Five', 'Hearts'),
('Five', 'Spades'),

('Six', 'Clubs'),
('Six', 'Diamonds'),
('Six', 'Hearts'),
('Six', 'Spades'),

('Seven', 'Clubs'),
('Seven', 'Diamonds'),
('Seven', 'Hearts'),
('Seven', 'Spades'),

('Eight', 'Clubs'),
('Eight', 'Diamonds'),
('Eight', 'Hearts'),
('Eight', 'Spades'),

('Nine', 'Clubs'),
('Nine', 'Diamonds'),
('Nine', 'Hearts'),
('Nine', 'Spades'),

('Ten', 'Clubs'),
('Ten', 'Diamonds'),
('Ten', 'Hearts'),
('Ten', 'Spades'),

('Jack', 'Clubs'),
('Jack', 'Diamonds'),
('Jack', 'Hearts'),
('Jack', 'Spades'),

('Queen', 'Clubs'),
('Queen', 'Diamonds'),
('Queen', 'Hearts'),
('Queen', 'Spades'),

('King', 'Clubs'),
('King', 'Diamonds'),
('King', 'Hearts'),
('King', 'Spades')

-- shuffles the deck

SELECT * FROM DECK_CARD ORDER BY RANDOM() */


DELIMITER $$
DROP PROCEDURE IF EXISTS JOIN_TABLE $$


CREATE PROCEDURE JOIN_TABLE (In playerName varchar(255), In pokerTable INT, OUT msg Varchar(100))
BEGIN
    /*

    Sits a player at a table under the conditions that
    1. the user exists in the database
    2. there is available seats
    3. the player is not already sitting at the table
    4. the player has enough chips in their purse to afford the buy-in of the table

    */

    SET @playerId = NULL;
    SET @seatId = NULL;
    SET @smallBlind = NULL;
    SET @purse = NULL;

    #fetch playerId of that player from player table using player name or 
    #else store player name directly into the pokerTable so direct check that player present in that table or not
    SELECT Username INTO @playerId
    FROM _USER
    WHERE Username=playerName;

    IF(@playerId IS NULL)THEN
    BEGIN
        SET msg='FAIL - USER NOT FOUND';
    END;
    ELSE
    BEGIN

        -- Find out the small blind of the given table - used to calculate the buy-in
        SELECT SmallBlind INTO @smallBlind
        FROM _TABLE
        WHERE TableId = pokerTable;

        -- Find out the # chips the user has in their purse
        SELECT Purse INTO @purse
        FROM _USER
        WHERE Username = @playerId;

        -- If the user has less chips in their purse than the amount of the buy-in (x4 the small blind)
        -- then they cannot sit at the table
        IF (@purse < (@smallBlind * 4)) THEN
        BEGIN
            SET msg = 'FAIL - NOT ENOUGH FUNDS';
        END;
        ELSE
        BEGIN

            #check that player present in that table or not
            SELECT _Index INTO @seatId
            FROM SEAT
            INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
            WHERE SEAT.SitterUsername=@playerId
            LIMIT 1;
            
            #if seat id is null it means that player have no seat in that table, then check is there any seats empty
            IF(@seatId IS NULL)THEN
            BEGIN

                SELECT _Index INTO @seatId
                FROM SEAT
                INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
                WHERE SEAT.SitterUsername IS NULL
                LIMIT 1;

                #if seat id is not null it means empty seat is present then give that seat to that player
                IF(@seatId IS NOT NULL)THEN
                BEGIN
                    UPDATE SEAT
                    SET SitterUsername=@playerId
                    WHERE _Index=@seatId AND TableId=pokerTable;

                    SET msg='SUCCESS';
                END;
                ELSE
                BEGIN
                SET msg='FAIL - NO EMPTY SEATS';
                END;
                END IF;
            END;
            ELSE 
            BEGIN
                SET msg='FAIL - PLAYER ALREADY AT TABLE';
            END  ; 
            END IF;
        END;
        END IF;
    END;
    END IF;

END $$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS LEAVE_TABLE $$



CREATE PROCEDURE LEAVE_TABLE (In playerName varchar(255), out msg varchar(100))
BEGIN

    SET @playerId = NULL;
    SET @tableId = NULL;

    SELECT Username INTO @playerId from _USER WHERE Username=playerName;

    IF(@playerId IS NULL)THEN
    BEGIN
        SET msg='FAIL - USER NOT FOUND';
    END;
    ELSE
    BEGIN
        SELECT TableId INTO @tableId 
        FROM SEAT 
        WHERE SitterUsername=playerName;

        IF(@tableId IS NULL)THEN
        BEGIN
            SET msg='FAIL - USER IS NOT AT A TABLE';
        END;
        ELSE
        BEGIN
            UPDATE SEAT
            SET SitterUsername = NULL
            WHERE SitterUsername=playerName;
            SET msg='SUCCESS';
        END;
        END IF;
    END;
    END IF;

END $$




DROP PROCEDURE IF EXISTS NEW_TABLE;

DELIMITER //

CREATE PROCEDURE NEW_TABLE (IN smallBlind INT)
BEGIN
    /*

    Creates a new table and initializes its seats and deck of cards

    */

    SET @playerId = NULL;
    SET @tableId = NULL;

    SELECT Username INTO @playerId from _USER WHERE Username=playerName;

    IF(@playerId IS NULL)THEN
    BEGIN
        SET msg='FAIL - USER NOT FOUND';
    END;
    ELSE
    BEGIN
        SELECT TableId INTO @tableId 
        FROM SEAT 
        WHERE SitterUsername=playerName;

        IF(@tableId IS NULL)THEN
        BEGIN
            SET msg='FAIL - USER IS NOT AT A TABLE';
        END;
        ELSE
        BEGIN
            UPDATE SEAT
            SET SitterUsername = NULL
            WHERE SitterUsername=playerName;
            SET msg='SUCCESS';
        END;
        END IF;
    END;
    END IF;

END $$

DROP PROCEDURE IF EXISTS GET_EMPTY_TABLE_SEAT $$

CREATE PROCEDURE GET_EMPTY_TABLE_SEAT (out tbl int)
BEGIN

    SET @tableId = NULL;

    SELECT TableId INTO @tableId
    FROM seat WHERE SitterUsername IS NULL;

    IF(@tableId IS NULL)THEN
    BEGIN
        SELECT TableId INTO @tableId
        FROM _TABLE ORDER BY TableId DESC;
        SET tbl := @tableId + 1;
    END;
    ELSE
    BEGIN
        SET tbl := @tableId;
    END;
    END IF;

END $$
DELIMITER ;


-- The NEW_MATCH creates a new match
DROP PROCEDURE IF EXISTS NEW_MATCH;

DELIMITER //

CREATE PROCEDURE NEW_MATCH (IN tableId INT, OUT msg VARCHAR(100))
BEGIN
    /*

    Creates a new poker match at a given table.

    */

    DECLARE numPlayers INT DEFAULT 0;

    DECLARE lastMatch INT DEFAULT NULL;

    -- Find out how many players are sitting at the given table
    SELECT COUNT(SitterUsername) INTO numPlayers
    FROM SEAT
    GROUP BY TableId
    HAVING TableId = tableId
    LIMIT 1;

    -- If there are less than 4 players sitting at the table
    -- then we cannot begin a new match.
    SET msg = CASE
		WHEN numPlayers < 4 THEN "FAIL - NOT ENOUGH PLAYERS"
        ELSE "SUCCESS"
	END;

    IF (msg = "SUCCESS") THEN
    BEGIN

        -- Find out the most recent match (before the one being created)
        SELECT MatchId INTO lastMatch
        FROM _MATCH
        WHERE TableId = tableId AND MatchId IS NOT NULL
        ORDER BY MatchId DESC
        LIMIT 1;

        -- Insert a new match into the database
        -- with the most recent match as its last match
        INSERT INTO _MATCH (TableId, LastMatchId)
        VALUES (tableId, lastMatch);

    END;
    END IF;

END; //

DELIMITER ;