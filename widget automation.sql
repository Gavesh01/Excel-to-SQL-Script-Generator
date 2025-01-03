CREATE PROCEDURE sp_GenerateWidgetSQLScript (@WidgetName Varchar(100), @organizationId int, @recordTypeID int = null, @ProfileName Varchar(100))
AS
BEGIN
    DECLARE @printWidget VARCHAR(MAX);
	DECLARE @answerOrder INT= 0 ;
	DECLARE @realValue INT = 0;
	DECLARE @previousQuestionCode VARCHAR(500);
	SET @previousQuestionCode = NULL;

    SET @printWidget = 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(10);
    SET @printWidget += 'BEGIN TRY;' + CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

    SET @printWidget += 'DECLARE @orgID INT = ' + CAST(@organizationId AS VARCHAR) + ';' + CHAR(13) + CHAR(10);
    SET @printWidget += 'DECLARE @recordTypeID INT = ' + ISNULL(CAST(@recordTypeID AS VARCHAR), 'NULL') + ';' + CHAR(13) + CHAR(10);
    SET @printWidget += 'DECLARE @recordID INT = ' + CAST(@organizationId AS VARCHAR) + ' ;' + CHAR(13) + CHAR(10);
    SET @printWidget += 'DECLARE @recordType VARCHAR(50) = ''' + ISNULL(@WidgetName, 'Unknown') + ''';' + CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);
	
	SET @printWidget += 'DECLARE @formID INT = (SELECT ISNULL(MAX(FormID), 0) + 1 FROM App_FormDef);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @pageID INT = (SELECT ISNULL(MAX(PageID), 0) + 1 FROM App_PageDef);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @groupID INT = (SELECT ISNULL(MAX(GroupID), 0) + 1 FROM App_GroupDef);'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'DECLARE @questionID INT = (SELECT ISNULL(MAX(QuestionID), 0) FROM App_QuestionDef);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @answerDefID INT = (SELECT ISNULL(MAX(AnswerDefID), 0) FROM App_AnswerDef);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @questionOrder INT = 0;'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'DECLARE @viewDefID INT;'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @viewComponentID INT = (SELECT MAX(ViewComponentID) + 1 FROM TR_ViewComponentRecords);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'DECLARE @displayOrder INT;'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'IF NOT EXISTS (SELECT * FROM App_RecordTypeDef WHERE RecordTypeID = @recordTypeID)'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordTypeDef VALUES(@recordTypeID, @recordType, ''com.hinext.app.record.RecordImplementation'');'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'IF NOT EXISTS(SELECT * FROM App_RecordDef WHERE RecordTypeID = @recordTypeID AND RecordID = @recordID)'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'BEGIN ;'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordDef VALUES(@recordTypeID, @recordID, @recordType, @recordType)'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordProperties VALUES (@recordTypeID, @recordID, 1, @orgID, ''DISPLAY_MASK'', 31);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordProperties VALUES (@recordTypeID, @recordID, 1, @orgID, ''SHOW_LAST_MODIFIED_USER'', ''true'');'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordProperties VALUES (@recordTypeID, @recordID, 1, @orgID, ''SHOW_LAST_MODIFIED_DATE'', ''true'');'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'INSERT INTO App_FormDef VALUES(@formID, @recordType, GetDate(), -999, GetDate(), NULL);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_PageDef values (@pageID, NULL, 0, 0, 1, @recordType, NULL, NULL, NULL, NULL, NULL, NULL);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_GroupDef values (@groupID, '''', NULL, NULL, NULL, NULL,NULL,NULL);'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'INSERT INTO App_PageGroup values (@pageID, @groupID, 1);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_FormPage values (@formID, @pageID, 1);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_RecordForm VALUES(@recordTypeID, @recordID, 1, @formID, 1, @orgID, '''', '''');'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	-- Loop through WidgetQuestion table to add dynamic questions
	DECLARE  @row INT, @column INT, @questionOrder INT, @questionLabel VARCHAR(500), @mainQuestionText VARCHAR(500), @answerType INT, @mandatory INT, @IsDate INT;
	DECLARE @questionCode VARCHAR(500), @answerSequence INT, @answerOptionText VARCHAR(500);

	-- Outer cursor for WidgetQuestion
	DECLARE question_cursor CURSOR FOR
	SELECT [Row],[Column],[QuestionOrder],[QuestionLabel],[QuestionText],[AnswerType],[Mandatory],[IsDate]
	FROM WidgetQuestion;

	OPEN question_cursor;
	FETCH NEXT FROM question_cursor INTO @row, @column, @questionOrder, @questionLabel, @mainQuestionText, @answerType, @mandatory, @IsDate;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Append dynamic SQL for questions
		SET @printWidget += 'SET @questionID = @questionID + 1;' + CHAR(13) + CHAR(10);
		SET @printWidget += 'SET @answerDefID = @answerDefID + 1;' + CHAR(13) + CHAR(10);
		SET @printWidget += 'SET @questionOrder = @questionOrder + 1;' + CHAR(13) + CHAR(10);
		SET @printWidget += CHAR(13) + CHAR(10);

		SET @printWidget += 'INSERT INTO App_QuestionDef VALUES (@questionID, ''' + @questionLabel + ''', ''' + @questionLabel + ''', ''' + @mainQuestionText + ''', NULL, NULL, NULL, 0);'+ CHAR(13) + CHAR(10);
		SET @printWidget += 'INSERT INTO App_AnswerDef VALUES (@answerDefID, ''' + @questionLabel + ''', ' + CAST(@answerType AS VARCHAR) +',  ' + CAST(@IsDate AS VARCHAR) +', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ''DEFAULT'', NULL, 0, 0, NULL, NULL, NULL);'+ CHAR(13) + CHAR(10);
		SET @printWidget += CHAR(13) + CHAR(10);

		-- Inner cursor for AnswerOptions
		DECLARE answer_cursor CURSOR FOR
		SELECT [QuestionCode], [AnswerSequence], [AnswerOptionText]
		FROM AnswerOptions;

		OPEN answer_cursor;
		FETCH NEXT FROM answer_cursor INTO @questionCode, @answerSequence, @answerOptionText;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @questionCode <> @previousQuestionCode
			BEGIN
				SET @answerOrder = -1;
				SET @realValue = -2;
			END;
		SET @previousQuestionCode = @questionCode;
		IF @questionCode = @questionLabel
		BEGIN
			SET @answerOrder += 1;
			IF @realValue = -1
				SET @realValue = 1;
			ELSE
				SET @realValue += 1;
			SET @printWidget += 'INSERT INTO App_AnswerDefContent VALUES (@answerDefID, '+ CAST(@answerOrder AS VARCHAR) + ', ''' + @answerOptionText + ''', '''+ CAST(@realValue AS VARCHAR) + ''', NULL, NULL, NULL, NULL);' + CHAR(13) + CHAR(10);
		END;

			FETCH NEXT FROM answer_cursor INTO @questionCode, @answerSequence, @answerOptionText;
		END;

		CLOSE answer_cursor;
		DEALLOCATE answer_cursor;

	SET @printWidget += CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_QuestionAnswer VALUES (@questionID, @answerDefID);'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_FormQuestion VALUES (@formID, @questionID, ' + CAST(@mandatory AS VARCHAR) + ', 7, @questionOrder, 0, NULL, 0);' + CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO App_GroupQuestion VALUES (@groupID, @questionID, ' + CAST(@row AS VARCHAR) + ', ' + CAST(@column AS VARCHAR) + ', 0, 0, 0);' + CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	FETCH NEXT FROM question_cursor INTO @row, @column, @questionOrder, @questionLabel, @mainQuestionText, @answerType, @mandatory, @IsDate;
	END;

	CLOSE question_cursor;
	DEALLOCATE question_cursor;

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	/*--Adding to Client Profile Page--*/ 
	SET @printWidget += 'IF EXISTS(SELECT * FROM TR_ViewDef WHERE OrgID = @orgID AND Title = ''' + CAST(@ProfileName AS VARCHAR) + ''')'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'BEGIN' + CHAR(13) + CHAR(10);
	SET @printWidget += 'SET @viewDefID = (SELECT ViewDefID FROM TR_ViewDef WHERE OrgID = @orgID AND Title = ''' + CAST(@ProfileName AS VARCHAR) + ''');'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'IF NOT EXISTS (SELECT * FROM TR_ViewComponents vc, TR_ViewComponentRecords vcr WHERE vcr.recordTypeID = @recordTypeID and vcr.ViewComponentID = vc.ViewComponentID and vc.ViewDefID = @viewDefID and vcr.recordID = @recordID)' + CHAR(13) + CHAR(10);
	SET @printWidget += 'BEGIN' ++ CHAR(13) + CHAR(10);
	SET @printWidget += 'SET @displayOrder = (SELECT isNull(MAX(Row), 1) FROM TR_ViewComponents where ViewDefID = @viewDefID) + 1;' + CHAR(13) + CHAR(10);
	SET @printWidget += 'PRINT(''Adding '' + @recordType + '' Record to View'')' + CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO TR_ViewComponents(ViewDefID, ViewComponentID, ComponentName, ComponentPage, Row, Col, CacheData,ViewComponentTypeID, DisplayMask) VALUES(@viewDefID, @viewComponentID, @recordType, NULL , @displayOrder, 1, 0, 1, 31)'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'INSERT INTO TR_ViewComponentRecords values (@viewComponentID, @recordTypeID, @recordID, 1, NULL, 1)'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'END'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'END' + CHAR(13) + CHAR(10);
	SET @printWidget += 'END' + CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'END TRY'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'BEGIN CATCH'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'SELECT'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'ERROR_NUMBER() AS ErrorNumber'+ CHAR(13) + CHAR(10);
	SET @printWidget += ',ERROR_SEVERITY() AS ErrorSeverity'+ CHAR(13) + CHAR(10);
	SET @printWidget += ',ERROR_STATE() AS ErrorState'+ CHAR(13) + CHAR(10);
	SET @printWidget += ',ERROR_PROCEDURE() AS ErrorProcedure'+ CHAR(13) + CHAR(10);
	SET @printWidget += ',ERROR_LINE() AS ErrorLine'+ CHAR(13) + CHAR(10);
	SET @printWidget += ',ERROR_MESSAGE() AS ErrorMessage'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'IF @@TRANCOUNT > 0'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'ROLLBACK TRANSACTION;'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'END CATCH ;'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);

	SET @printWidget += 'IF @@TRANCOUNT > 0'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'BEGIN'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'print ''COMPLETE'''+ CHAR(13) + CHAR(10);
	SET @printWidget += 'ROLLBACK TRANSACTION;'+ CHAR(13) + CHAR(10);
	SET @printWidget += '--COMMIT TRANSACTION;'+ CHAR(13) + CHAR(10);
	SET @printWidget += 'END'+ CHAR(13) + CHAR(10);
	SET @printWidget += CHAR(13) + CHAR(10);
    
	SET @printWidget += 'GO'+ CHAR(13) + CHAR(10);

    DECLARE @chunk VARCHAR(MAX);
    WHILE LEN(@printWidget) > 0
    BEGIN
        SET @chunk = LEFT(@printWidget, 4000);
        PRINT @chunk; 
        SET @printWidget = SUBSTRING(@printWidget, 4001, LEN(@printWidget));
    END;
END