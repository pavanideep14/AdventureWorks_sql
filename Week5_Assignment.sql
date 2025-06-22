DROP PROCEDURE IF EXISTS ProcessSubjectRequests;
GO

CREATE PROCEDURE ProcessSubjectRequests
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Declare required variables
        DECLARE @StudentID VARCHAR(50);
        DECLARE @RequestedSubjectID VARCHAR(50);
        DECLARE @CurrentSubjectID VARCHAR(50);

        -- Declare cursor for processing SubjectRequest table
        DECLARE request_cursor CURSOR FOR
            SELECT StudentID, SubjectID FROM SubjectRequest;

        OPEN request_cursor;
        FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the student already exists in SubjectAllotments
            IF EXISTS (SELECT 1 FROM SubjectAllotments WHERE StudentID = @StudentID)
            BEGIN
                -- Get the currently active subject
                SELECT @CurrentSubjectID = SubjectID 
                FROM SubjectAllotments 
                WHERE StudentID = @StudentID AND Is_Valid = 1;

                -- If the requested subject is different from the current one
                IF @CurrentSubjectID <> @RequestedSubjectID
                BEGIN
                    -- Mark the current subject as invalid
                    UPDATE SubjectAllotments
                    SET Is_Valid = 0
                    WHERE StudentID = @StudentID AND Is_Valid = 1;

                    -- Insert the new requested subject as valid
                    INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                    VALUES (@StudentID, @RequestedSubjectID, 1);
                END
                -- If it's the same subject, do nothing
            END
            ELSE
            BEGIN
                -- Student does not exist, insert the new subject directly
                INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                VALUES (@StudentID, @RequestedSubjectID, 1);
            END

            -- Move to next record
            FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;
        END

        -- Clean up
        CLOSE request_cursor;
        DEALLOCATE request_cursor;

        -- Clear SubjectRequest table after processing
        DELETE FROM SubjectRequest;

        COMMIT; -- Commit all changes

    END TRY
    BEGIN CATCH
        -- If an error occurs, rollback all changes
        ROLLBACK;

        -- Print detailed error info (optional)
        PRINT 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
