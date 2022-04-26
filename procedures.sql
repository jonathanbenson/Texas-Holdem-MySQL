-- used for testing

DROP PROCEDURE IF EXISTS CLEAN;

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



-- Procedure to place player at table, if not already at table, and table has atleast 1 empty seat
DELIMITER $$
DROP PROCEDURE IF EXISTS JOIN_TABLE $$


CREATE PROCEDURE JOIN_TABLE (In playerName varchar(255), In pokerTable INT, OUT msg Varchar(100))
BEGIN

    SET @playerId = NULL;
    SET @tableId = NULL;
    
    #fetch playerId of that player from player table using player name or 
    #else store player name directly into the pokerTable so direct check that player present in that table or not
    SELECT Username into @playerId FROM _USER WHERE Username=playerName;
    
    #check that player present in that table or not
    SELECT _Index INTO @seatId
    FROM SEAT
    INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
    WHERE player_id=@playerId
    LIMIT 1;
    
    #if seat id is null it means that player have no seat in that table, then check is there any seats empty
    if(@seatId IS NULL)THEN
    BEGIN

        SELECT _Index into @seatId
        FROM SEAT
        INNER JOIN _TABLE ON _TABLE.TableId=pokerTable
        WHERE SEAT.SitterUsername = NULL
        LIMIT 1;

        #if seat id is not null it means empty seat is present then give that seat to that player
        if(@seatId IS NOT NULL)THEN
        BEGIN
            UPDATE SEAT
            SET SitterUsername=@playerId
            WHERE _Index=@seatId;

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