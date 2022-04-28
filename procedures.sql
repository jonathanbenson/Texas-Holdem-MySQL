-- used for testing

DROP PROCEDURE IF EXISTS CLEAN;

DELIMITER //

CREATE PROCEDURE CLEAN ()
BEGIN

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

END; //

DELIMITER ;



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



-- FIXME: NOT TESTED

DROP PROCEDURE IF EXISTS NEW_TABLE;

DELIMITER //

CREATE PROCEDURE NEW_TABLE (IN smallBlind, OUT msg)
BEGIN

    -- Insert new table into database with given small blind
    INSERT INTO _TABLE (SmallBlind) VALUES (smallBlind);

    SET @newTableId = NULL;

    -- Retrieve the table id of the newly created table
    SELECT MAX(TableId) INTO @newTableId
    FROM _TABLE
    GROUP BY _TABLE.TableId;

    -- Initialize the 10 seats for the new table
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 0);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 1);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 2);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 3);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 4);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 5);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 6);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 7);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 8);
    INSERT INTO SEAT (TableId, _Index) VALUES (@newTableId, 9);

    -- Initialize the newly created table's deck
    INSERT INTO DECK_CARD
    SELECT TableId, Face, Suit
    FROM (SELECT @newTableId as TableId), CARD;

END; //

DELIMITER ;
