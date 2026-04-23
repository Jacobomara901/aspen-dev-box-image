SET FOREIGN_KEY_CHECKS=0;
INSERT INTO account_profiles (authenticationMethod, databaseHost, databaseName, databasePassword, databasePort, databaseTimezone, databaseUser, driver, id, ils, loginConfiguration, name, patronApiUrl, recordSource, vendorOpacUrl, weight) VALUES ('ils', 'kohadev-db-1', 'koha_kohadev', 'password', 3306, 'GMT', 'koha_kohadev', 'Koha', 2, 'koha', 'barcode_pin', 'ils', 'http://kohadev-koha-1:8080', 'ils', 'http://kohadev-koha-1:8080', 1);
INSERT INTO indexing_profiles (barcode, callNumber, catalogDriver, collection, dateCreated, dateCreatedFormat, doAutomaticEcontentSuppression, dueDate, filenamesToInclude, format, formatSource, iType, indexingClass, itemRecordNumber, itemTag, lastCheckinFormat, location, marcEncoding, marcPath, name, noteSubfield, recordNumberSubfield, recordNumberTag, recordUrlComponent, runFullUpdate, shelvingLocation, totalCheckouts, totalRenewals, useItemBasedCallNumbers, volume) VALUES ('p', 'o', 'Koha', '8', 'd', 'yyyy-MM-dd', 1, 'k', '.*\\.ma?rc', 'y', 'item', 'y', 'Koha', '9', '952', '', 'a', 'UTF8', '/data/aspen-discovery/dev.localhost/ils/marc', 'ils', 'z', 'c', '999', 'Record', 1, 'c', 'l', 'm', 1, 'h');
UPDATE library SET accountProfileId = 2 WHERE libraryId = 1;
UPDATE modules SET enabled = 1 WHERE name = 'Koha';
INSERT INTO library_records_to_include(
    libraryId, indexingProfileId, location, subLocation,
    includeHoldableOnly, includeItemsOnOrder, includeEContent, weight,
    includeExcludeMatches, markRecordsAsOwned
) VALUES (1, 1, '.*', '.*', 0, 1, 1, 1, 1, 1);

INSERT INTO status_map_values (indexingProfileId, value, status, groupedStatus, suppress) VALUES
(1, 'Checked Out', 'Checked Out', 'Checked Out', 0),
(1, 'Claims Returned', 'Claims Returned', 'Currently Unavailable', 1),
(1, 'On Shelf', 'On Shelf', 'On Shelf', 0),
(1, 'Damaged', 'Damaged', 'Currently Unavailable', 1),
(1, 'In Transit', 'In Transit', 'In Transit', 0),
(1, 'Library Use Only', 'Library Use Only', 'Library Use Only', 0),
(1, 'Long Overdue (Lost)', 'Long Overdue (Lost)', 'Currently Unavailable', 1),
(1, 'Lost', 'Lost', 'Currently Unavailable', 1),
(1, 'Lost and Paid For', 'Lost and Paid For', 'Currently Unavailable', 1),
(1, 'Missing', 'Missing', 'Currently Unavailable', 1),
(1, 'On Hold Shelf', 'On Hold Shelf', 'Checked Out', 0),
(1, 'On Order', 'On Order', 'On Order', 0),
(1, 'Discard', 'Discard', 'Currently Unavailable', 1),
(1, 'Lost Claim', 'Lost Claim', 'Currently Unavailable', 1);

INSERT INTO translation_maps (indexingProfileId, name, usesRegularExpressions) VALUES
(1, 'location', 0),
(1, 'sub_location', 0),
(1, 'shelf_location', 0),
(1, 'itype', 0);
SET FOREIGN_KEY_CHECKS=1;
