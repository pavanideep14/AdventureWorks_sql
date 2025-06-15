DROP TABLE IF EXISTS Allotments;
DROP TABLE IF EXISTS UnallottedStudents;
DROP TABLE IF EXISTS StudentPreference;
DROP TABLE IF EXISTS SubjectDetails;
DROP TABLE IF EXISTS StudentDetails;



-- Table: StudentDetails
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA DECIMAL(3,1),
    Branch VARCHAR(50),
    Section VARCHAR(10)
);

-- Table: SubjectDetails
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

-- Table: StudentPreference
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    CONSTRAINT UC_StudentPreference UNIQUE (StudentId, Preference, SubjectId)
);

-- Table: Allotments
CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT
);

-- Table: UnallottedStudents
CREATE TABLE UnallottedStudents (
    StudentId INT
);
INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

-- Preferences for Mohit Agarwal (159103036)
INSERT INTO StudentPreference VALUES (159103036, 'PO1491', 1);
INSERT INTO StudentPreference VALUES (159103036, 'PO1492', 2);
INSERT INTO StudentPreference VALUES (159103036, 'PO1493', 3);
INSERT INTO StudentPreference VALUES (159103036, 'PO1494', 4);
INSERT INTO StudentPreference VALUES (159103036, 'PO1495', 5);

-- Preferences for Rohit Agarwal (159103037)
INSERT INTO StudentPreference VALUES (159103037, 'PO1492', 1);
INSERT INTO StudentPreference VALUES (159103037, 'PO1491', 2);
INSERT INTO StudentPreference VALUES (159103037, 'PO1494', 3);
INSERT INTO StudentPreference VALUES (159103037, 'PO1493', 4);
INSERT INTO StudentPreference VALUES (159103037, 'PO1495', 5);

-- Preferences for Shohit Garg (159103038)
INSERT INTO StudentPreference VALUES (159103038, 'PO1493', 1);
INSERT INTO StudentPreference VALUES (159103038, 'PO1492', 2);
INSERT INTO StudentPreference VALUES (159103038, 'PO1494', 3);
INSERT INTO StudentPreference VALUES (159103038, 'PO1495', 4);
INSERT INTO StudentPreference VALUES (159103038, 'PO1491', 5);

-- Preferences for Mrinal Malhotra (159103039)
INSERT INTO StudentPreference VALUES (159103039, 'PO1495', 1);
INSERT INTO StudentPreference VALUES (159103039, 'PO1494', 2);
INSERT INTO StudentPreference VALUES (159103039, 'PO1493', 3);
INSERT INTO StudentPreference VALUES (159103039, 'PO1492', 4);
INSERT INTO StudentPreference VALUES (159103039, 'PO1491', 5);

-- Preferences for Mehreet Singh (159103040)
INSERT INTO StudentPreference VALUES (159103040, 'PO1494', 1);
INSERT INTO StudentPreference VALUES (159103040, 'PO1492', 2);
INSERT INTO StudentPreference VALUES (159103040, 'PO1493', 3);
INSERT INTO StudentPreference VALUES (159103040, 'PO1495', 4);
INSERT INTO StudentPreference VALUES (159103040, 'PO1491', 5);

-- Preferences for Arjun Tehlan (159103041)
INSERT INTO StudentPreference VALUES (159103041, 'PO1491', 1);
INSERT INTO StudentPreference VALUES (159103041, 'PO1493', 2);
INSERT INTO StudentPreference VALUES (159103041, 'PO1492', 3);
INSERT INTO StudentPreference VALUES (159103041, 'PO1494', 4);
INSERT INTO StudentPreference VALUES (159103041, 'PO1495', 5);
GO


DROP PROCEDURE IF EXISTS AllotStudentsToSubjects;
GO
CREATE PROCEDURE AllotStudentsToSubjects
AS
BEGIN
    -- Clear previous allotments
    DELETE FROM Allotments;
    DELETE FROM UnallottedStudents;

    DECLARE @StudentId INT, @SubjectId VARCHAR(10), @RemainingSeats INT;

    -- Cursor for students in descending GPA order
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId FROM StudentDetails ORDER BY GPA DESC;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Allocated BIT = 0;

        -- Cursor for student preferences
        DECLARE pref_cursor CURSOR FOR
            SELECT SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId
            ORDER BY Preference;

        OPEN pref_cursor;
        FETCH NEXT FROM pref_cursor INTO @SubjectId;

        WHILE @@FETCH_STATUS = 0 AND @Allocated = 0
        BEGIN
            SELECT @RemainingSeats = RemainingSeats FROM SubjectDetails WHERE SubjectId = @SubjectId;

            IF @RemainingSeats > 0
            BEGIN
                -- Allot and update seats
                INSERT INTO Allotments (SubjectId, StudentId) VALUES (@SubjectId, @StudentId);
                UPDATE SubjectDetails SET RemainingSeats = RemainingSeats - 1 WHERE SubjectId = @SubjectId;
                SET @Allocated = 1;
            END

            FETCH NEXT FROM pref_cursor INTO @SubjectId;
        END

        CLOSE pref_cursor;
        DEALLOCATE pref_cursor;

        IF @Allocated = 0
        BEGIN
            INSERT INTO UnallottedStudents (StudentId) VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;


-- Execute the procedure
EXEC AllotStudentsToSubjects;

-- View allotted students
SELECT * FROM Allotments;

-- View unallotted students
SELECT * FROM UnallottedStudents;



PRINT CONCAT('Allotted: ', @StudentId, ' to ', @SubjectId);
-- or
PRINT CONCAT('Unallotted: ', @StudentId);


UPDATE SubjectDetails
SET RemainingSeats = MaxSeats;

