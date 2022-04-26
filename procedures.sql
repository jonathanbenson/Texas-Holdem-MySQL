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



-- Procedure to place player at table, if not already at table, and table has atleast 1 empty seat
DELIMITER $$
DROP PROCEDURE IF EXISTS checkTable$$
CREATE PROCEDURE checkTable(In playerName varchar(50),OUT msg Varchar(100))
BEGIN

    SET @playerId =null;
    SET @tableId=null;
    
    #fetch playerId of that player from player table using player name or 
    #else store player name directly into the pokerTable so direct check that player present in that table or not
    select playerId into @playerId from player where player_name=playerName;
    
    #check that player present in that table or not
    select seat_id into @seatId from pokerTable where player_id=@playerId limit 1;
    
    #if seat id is null it means that player have no seat in that table, then check is there any seats empty
    if(@seatId is null)THEN
    BEGIN
         select seat_id  into @seatId from pokerTable where seat_state ='EMPTY' limit 1;
         #if seat id is not null it means empty seat is present then give that seat to that player
         if(@seatId is not null)THEN
         BEGIN
            update pokerTable set player_id=@playerId,seat_state='FULL' where seat_id=@seatId;
            SET msg='PLAYER GOT THE SEAT ';
         END;
         ELSE
         BEGIN
                        SET msg='Table has no empty seats';
         END;
         END IF;
    END;
    ELSE 
    BEGIN
        SET msg='Player is already at table';
    END  ; 
    END IF;

END $$
DELIMITER ;