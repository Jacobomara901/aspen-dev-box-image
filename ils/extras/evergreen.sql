INSERT INTO library_records_to_include(
    libraryId, indexingProfileId, location, subLocation,
    includeHoldableOnly, includeItemsOnOrder, includeEContent, weight,
    includeExcludeMatches, markRecordsAsOwned
) VALUES (1, 1, '.*', '.*', 0, 1, 1, 1, 1, 1);

INSERT INTO status_map_values (indexingProfileId, value, status, groupedStatus, suppress) VALUES
(1, 'Available', 'On Shelf', 'On Shelf', 0),
(1, 'Reshelving', 'Reshelving', 'On Shelf', 0),
(1, 'Checked out', 'Checked Out', 'Checked Out', 0),
(1, 'On holds shelf', 'On Hold Shelf', 'Checked Out', 0),
(1, 'In transit', 'In Transit', 'In Transit', 0),
(1, 'In process', 'In Processing', 'In Processing', 0),
(1, 'Cataloging', 'In Processing', 'In Processing', 0),
(1, 'On order', 'On Order', 'On Order', 0),
(1, 'Reserves', 'Reserves', 'Library Use Only', 0),
(1, 'On reservation shelf', 'On Reservation Shelf', 'Library Use Only', 0),
(1, 'ILL', 'ILL', 'Currently Unavailable', 0),
(1, 'Bindery', 'Bindery', 'Currently Unavailable', 0),
(1, 'Canceled Transit', 'Canceled Transit', 'Currently Unavailable', 0),
(1, 'Damaged', 'Damaged', 'Currently Unavailable', 1),
(1, 'Lost', 'Lost', 'Currently Unavailable', 1),
(1, 'Lost and Paid', 'Lost and Paid', 'Currently Unavailable', 1),
(1, 'Long Overdue', 'Long Overdue', 'Currently Unavailable', 1),
(1, 'Missing', 'Missing', 'Currently Unavailable', 1),
(1, 'Discard/Weed', 'Discard', 'Currently Unavailable', 1);

INSERT INTO translation_maps (indexingProfileId, name, usesRegularExpressions) VALUES
(1, 'location', 0),
(1, 'sub_location', 0),
(1, 'shelf_location', 0),
(1, 'itype', 0);
