/* 

Cleaning Data Using SQL Queries 

*/

SELECT *
FROM [portfolio-project].dbo.nashvillehousing;

-- Standardize Date Format

ALTER TABLE nashvillehousing
ALTER COLUMN SaleDate date;

SELECT SaleDate
FROM nashvillehousing;

-- Populate Property Address Data

SELECT *
FROM nashvillehousing
WHERE PropertyAddress is null
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null;

-- Separating Combined PropertyAddress (Address, City)

SELECT PropertyAddress
FROM nashvillehousing;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD Address NVARCHAR(255);

UPDATE nashvillehousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE nashvillehousing
ADD City NVARCHAR(255);

UPDATE nashvillehousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

-- Separating Combined OwnerAddress (Address, City, State)

SELECT OwnerAddress
FROM nashvillehousing;

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerStreetAddress NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE nashvillehousing
ADD OwnerCity NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE nashvillehousing
ADD OwnerState NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Update 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant Column

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END;

-- Remove Duplicates

WITH RowNumCTE AS (
SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
	ORDER BY
		UniqueID
		) row_num
FROM nashvillehousing
	)
	
DELETE 
FROM RowNumCTE
WHERE row_num > 1;

WITH RowNumCTE AS (
SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
	ORDER BY
		UniqueID
		) row_num
FROM nashvillehousing
	)

SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- Delete Unused Columns

SELECT *
FROM nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;