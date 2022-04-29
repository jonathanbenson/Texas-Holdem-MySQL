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
