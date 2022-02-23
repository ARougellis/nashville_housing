/*
			---------------------------------------------
			---- CLEANING THE NASHVILLE HOUSING DATA ----
            ---------------------------------------------
*/

USE nashville_housing; 

SELECT * 
FROM housing_data;

----------------------------------------------------------------------------------------------------
-- 			-PartI-
-- Standardize the Date Format --

SELECT 
	SaleDate 
    -- DATE_FORMAT( STR_TO_DATE( SaleDate, '%M %e, %Y' ) , '%Y-%m-%d' ) AS sale_date -- > this converts DATE to a format sql likes
FROM housing_data;

-- Now to UPDATE the dataset...
-- 			NOTE: 
-- 				required me to turn off __Safe Updates__
/*
```
UPDATE housing_data
SET 
	SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %e, %Y'), '%Y-%m-%d'); 
```
*/

----------------------------------------------------------------------------------------------------
/*
			-PartII-
Populate the `ProperyAddress` data
			- there are empty values in `ProperyAddress` column
					and we want to populate them
*/

-- If `ParcelID` is the same, address is the same. 
SELECT *
FROM housing_data
-- WHERE PropertyAddress ="";
ORDER BY ParcelID; 

-- This Query selects `ProperyAddress` entrys that are NULL/nonexistant
-- 			and joins the table onto itself to match the `ParcelID` with 
-- 			the address
-- 			NOTE: 
-- 				if no rows are retrieved, then all `ProperyAddress` entries have an address
SELECT 
	nhd.ParcelID, 
    nhd.PropertyAddress,
    nhd_copy.ParcelID, 
    nhd_copy.PropertyAddress
FROM housing_data as nhd
JOIN housing_data as nhd_copy
	ON nhd.ParcelID = nhd_copy.ParcelID 
    AND nhd.UniqueID != nhd_copy.UniqueID -- > dont want any dupicate UniqueID
WHERE nhd.PropertyAddress = "";

-- This _UPDATES_ the `PropertyAddress` 
-- 		to insert addresses into `PropertyAddress` that have matching `ParcelID`
/*
```
UPDATE housing_data AS nhd
JOIN housing_data as nhd_copy
	ON nhd.ParcelID = nhd_copy.ParcelID 
    AND nhd.UniqueID != nhd_copy.UniqueID
SET nhd.PropertyAddress = nhd_copy.PropertyAddress
WHERE nhd.PropertyAddress = "";
```
*/



----------------------------------------------------------------------------------------------------
-- 						-PartIII-
-- Break Up the Address Columns into Individual Columns (ie. address, city, state)

-- ---> SPLITTING `PropertyAddress` <---
-- 				(using SUBSTRING(value, start_position, end_position) )
SELECT 
	PropertyAddress, 
	substring( PropertyAddress, 1, instr(PropertyAddress, ',')-1 ) AS Address,  -- > instr(original_string, sub_string) = INT
    substring( PropertyAddress, instr(PropertyAddress, ',')+1, length(PropertyAddress)) AS City 
FROM housing_data AS nhd;


-- ---> SPLITTING `OwnerAddress` <---
--  			(using SUBSTRING_INDEX(string, delimiter, count) ) 
SELECT 
	OwnerAddress, 
    substring_index(OwnerAddress, ",", 1) AS OwnerSplitAddress, 
    substring_index(substring_index(OwnerAddress,",",2), ",", -1) AS OwnerSplitCity, 
    substring_index(OwnerAddress, ",", -1) AS OwnerSplitState
FROM housing_data;

/*
-- > UPDATING the dataset to include the above 

ALTER TABLE housing_data
	ADD PropertySplitAddress nvarchar(255) AFTER PropertyAddress,
    ADD PropertySplitCity nvarchar(255) AFTER PropertySplitAddress, 
	ADD OwnerSplitAddress nvarchar(255) AFTER OwnerAddress,
    ADD OwnerSplitCity nvarchar(255) AFTER OwnerSplitAddress, 
    ADD OwnerSplitState nvarchar(255) AFTER OwnerSplitCity;

UPDATE housing_data
	SET PropertySplitAddress = substring( PropertyAddress, 1, instr(PropertyAddress, ',')-1 );
UPDATE housing_data
	SET PropertySplitCity = substring( PropertyAddress, instr(PropertyAddress, ',')+1, length(PropertyAddress) );
UPDATE housing_data
	SET OwnerSplitAddress = substring_index(OwnerAddress, ",", 1) ;
UPDATE housing_data
	SET OwnerSplitCity = substring_index(substring_index(OwnerAddress,",",2), ",", -1);
UPDATE housing_data
	SET OwnerSplitState = substring_index(OwnerAddress, ",", -1);
*/



----------------------------------------------------------------------------------------------------
-- 				-PartIV-
-- Changing Y/N to Yes/No in `SoldAsVacant`
-- 			- using case statements

SELECT 
	DISTINCT SoldAsVacant, 
    COUNT(SoldAsVacant)
FROM housing_data
GROUP BY SoldAsVacant; -- <--- Here we see that there are Yes/No AND Y/N entries
-- 									(run this again at teh end to test if update worked)


-- Lets use case statements to turn Y/N entries into Yes/No...
SELECT 
	SoldAsVacant, 
    CASE WHEN SoldAsVacant = "Y" THEN "Yes" 
		 WHEN SoldAsVacant = "N" THEN "No"
         ELSE SoldAsVacant
		 END
FROM housing_data;

-- NOW, lets update the table to turn Y/N entries into Yes/No using case statements. 
--
-- UPDATE housing_data
-- SET SoldAsVacant = CASE WHEN SoldAsVacant = "Y" THEN "Yes" 
-- 						WHEN SoldAsVacant = "N" THEN "No"
-- 						ELSE SoldAsVacant
-- 						END;



----------------------------------------------------------------------------------------------------
-- 			-PartV-
-- ---> REMOVING DUPLICATES <---

-- First, we find where there are duplicates
-- Using....
-- 		- ROW_NUMBER() OVER (<partition_definition> <order_definition>)
-- 				- partition_definition == PARTITION BY <expression>,[{,<expression>}...]
-- 				- order_definition == ORDER BY <expression> [ASC|DESC],[{,<expression>}...]
-- 
SELECT 
	UniqueID, 
	ParcelID, 
    PropertyAddress, 
    rep_row_num
FROM (
	SELECT 
		*, 
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID, 
						 PropertyAddress, 
						 LegalReference, 
						 OwnerName, 
						 LandValue, 
						 YearBuilt
			Order By PropertyAddress
		) AS rep_row_num -- <--- Gives INT value. If value > 1, then all above criterias are being repeated a value-num of times
	FROM housing_data ) AS row_num_table
WHERE rep_row_num > 1;

/*
In order to DELETE these duplicates...
```
DELETE FROM housing_data
WHERE UniqueID IN (
					<last_query>
) ;
```
*/



----------------------------------------------------------------------------------------------------
/*
					-PartVI-
		---> Removing Unused Columns <---

I wont be removing any columns as I dont see it necessary. 
		NOTE:
			Always perform data commands (ie. DELETE, ALTER TABLE, UPDATE, etc) on a 
            copy of the original data set. NEVER on the og raw dataset. 

BUT, if I was to delete any columns, I would delete `PropertyAddress` and `OwnerAddress` b/c 
		we already split those columns up into columns of more use. 
			ie. PropertyAddress --> {PropertySplitAddress, PropertySplitCity}

```
ALTER TABLE nashville_housing
DROP COLUMN 
	PropertyAddress, 
    OwnerAddress
```

*/
