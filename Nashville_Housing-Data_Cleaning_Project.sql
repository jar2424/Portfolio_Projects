-- Data Cleaning in SQL for Nashville Housing Dataset

-- Check the data
SELECT *
FROM public."Nashville Housing";

-- Alter date format
ALTER TABLE public."Nashville Housing"
ALTER COLUMN "Sale_Date" TYPE date;

-- Populate Missing Addresses - Join on Parcel_IDs 
WITH NonNullAddresses AS (
    SELECT "Parcel_ID", "Property_Address"
    FROM public."Nashville Housing"
    WHERE "Property_Address" IS NOT NULL
)
UPDATE public."Nashville Housing" AS dest
SET "Property_Address" = src."Property_Address"
FROM NonNullAddresses AS src
WHERE dest."Parcel_ID" = src."Parcel_ID"
  AND dest."Property_Address" IS NULL;

-- Breaking out Addresses into individual columns (Address, City, State)
	-- 1. Property Addresses
ALTER TABLE public."Nashville Housing"
ADD COLUMN "Property_Split_Address" text;

ALTER TABLE public."Nashville Housing"
ADD COLUMN "Property_Split_City" text;

UPDATE public."Nashville Housing"
SET "Property_Split_Address" = SPLIT_PART("Property_Address", ',', 1);

UPDATE public."Nashville Housing"
SET "Property_Split_City" = SPLIT_PART("Property_Address", ',', 2);

	-- 2. Owner Addresses
ALTER TABLE public."Nashville Housing"
ADD COLUMN "Owner_Split_Address" text;

ALTER TABLE public."Nashville Housing"
ADD COLUMN "Owner_Split_City" text;

ALTER TABLE public."Nashville Housing"
ADD COLUMN "Owner_Split_State" text;

UPDATE public."Nashville Housing"
SET "Owner_Split_Address" = SPLIT_PART("Owner_Address", ',', 1);

UPDATE public."Nashville Housing"
SET "Owner_Split_City" = SPLIT_PART("Owner_Address", ',', 2);

UPDATE public."Nashville Housing"
SET "Owner_Split_State" = SPLIT_PART("Owner_Address", ',', 3);

-- Change True and False to Yes and No in "Sold as Vacant" field
	-- Check for total vacancies
SELECT DISTINCT("Sold_As_Vacant"), COUNT("Sold_As_Vacant")
FROM public."Nashville Housing"
GROUP BY "Sold_As_Vacant"

	-- Update
UPDATE public."Nashville Housing"
SET "Sold_As_Vacant" = (
	CASE 
		 WHEN "Sold_As_Vacant" = 'false' THEN 'No'
		 WHEN "Sold_As_Vacant" = 'true'  THEN 'Yes'
		 ELSE "Sold_As_Vacant"
		 END)

-- Remove Duplicates
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY "Parcel_ID",
                            "Property_Address",
                            "Sale_Price",
                            "Sale_Date",
                            "Legal_Reference"
               ORDER BY "Unique_ID"
           ) AS row_num
    FROM public."Nashville Housing"
)
DELETE FROM public."Nashville Housing"
WHERE ("Parcel_ID", "Property_Address", "Sale_Price", "Sale_Date", "Legal_Reference", "Unique_ID") IN (
    SELECT "Parcel_ID", "Property_Address", "Sale_Price", "Sale_Date", "Legal_Reference", "Unique_ID"
    FROM RowNumCTE
    WHERE row_num > 1
);

-- Delete Unused Columns
ALTER TABLE public."Nashville Housing"
DROP COLUMN "Owner_Address",
DROP COLUMN	"Property_Address", 
DROP COLUMN	"Tax_District";