-- used for testing

DROP PROCEDURE IF EXISTS CLEAN;

DELIMITER //

CREATE PROCEDURE CLEAN ()
BEGIN

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

INSERT INTO DECK_CARD (Face, Suit) VALUES

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

SELECT * FROM DECK_CARD ORDER BY RANDOM()


-- Procedure to place player at table, if not already at table, and table has atleast 1 empty seat
DELIMITER $$
DROP PROCEDURE IF EXISTS JOIN_TABLE $$


CREATE PROCEDURE JOIN_TABLE (In playerName varchar(255), In pokerTable INT, OUT msg Varchar(100))
BEGIN

    SET @playerId = NULL;
    SET @seatId = NULL;

    #fetch playerId of that player from player table using player name or 
    #else store player name directly into the pokerTable so direct check that player present in that table or not
    SELECT Username INTO @playerId FROM _USER WHERE Username=playerName;
    
    #check that player present in that table or not
    SELECT _Index INTO @seatId
    FROM SEAT
    INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
    WHERE SEAT.SitterUsername=@playerId
    LIMIT 1;
    
    #if seat id is null it means that player have no seat in that table, then check is there any seats empty
    if(@seatId IS NULL)THEN
    BEGIN

        SELECT _Index INTO @seatId
        FROM SEAT
        INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
        WHERE SEAT.SitterUsername IS NULL
        LIMIT 1;

        #if seat id is not null it means empty seat is present then give that seat to that player
        if(@seatId IS NOT NULL)THEN
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

END $$
DELIMITER ;
<<<<<<< HEAD



-- The NEW_TABLE procedure creates a new table and initializes its seats and deck of cards
DROP PROCEDURE IF EXISTS NEW_TABLE;

DELIMITER //

CREATE PROCEDURE NEW_TABLE (IN smallBlind INT)
BEGIN

    -- Variable used for the newly created table id
    DECLARE newTableId INT DEFAULT 0;

    -- Variables used for initializing the cards in the table's deck
    DECLARE count INT DEFAULT 1;
    DECLARE currentFace VARCHAR(30) DEFAULT "";
    DECLARE currentSuit VARCHAR(30) DEFAULT "";

    -- Insert new table into database with given small blind
    INSERT INTO _TABLE (SmallBlind) VALUES (smallBlind);

    -- Retrieve the table id of the newly created table
    SELECT MAX(TableId) INTO newTableId
    FROM _TABLE
    GROUP BY TableId
    LIMIT 1;

    -- Initialize the 10 seats for the new table
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 0);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 1);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 2);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 3);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 4);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 5);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 6);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 7);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 8);
    INSERT INTO SEAT (TableId, _Index) VALUES (newTableId, 9);

    -- Initialize cards in the table's deck
    WHILE count <= 52 DO

        SELECT Face INTO currentFace
        FROM CARD
        WHERE Id = count
        LIMIT 1;

        SELECT Suit INTO currentSuit
        FROM CARD
        WHERE Id = count
        LIMIT 1;

        INSERT INTO DECK_CARD (TableId, Face, Suit, _Index)
        VALUES (newTableId, currentFace, currentSuit, count);

        SET count = count + 1;

    END WHILE;

END; //

DELIMITER ;
=======
>>>>>>> acab86a237927a479f4057440da5e3ace8bfe8ca
