-- Cleaning data 
select *
from nashvillehousing
;
-- Standardize date format 
alter table nashvillehousing
add SaleDateConverted DATE
;
update nashvillehousing
set SaleDateConverted = str_to_date(SaleDate, '%M %e,%Y')
;
-- Populate Property Address Data;
update nashvillehousing
set PropertyAddress = (select ifnull(a.PropertyAddress,b.PropertyAddress)
from nashvillehousing a join nashvillehousing b
on a.ParcelID = b.ParcelID
and a.UniqueID != b.UniqueID
where a.PropertyAddress = '' )
;
-- Breaking out property address into individual columns (address, city, state)
-- use substring + locate
alter table nashvillehousing
add PropertySplitAddress varchar(225),
add PropertySplitCity varchar(225)
;
update nashvillehousing
set PropertySplitAddress = substring(PropertyAddress, 1, locate(',', PropertyAddress)-1),
PropertySplitCity = substring(PropertyAddress, locate(',', PropertyAddress)+1, length(PropertyAddress))
;
-- Breaking out owner address into individual columns (address, city, state)
-- use substring_index
alter table nashvillehousing
add OwnerSplitState varchar(225),
add OwnerSplitAddress varchar(225),
add OwnerSplitCity varchar(225)
;
update nashvillehousing
set OwnerSplitState = substring_index(OwnerAddress, ',', -1),
OwnerSplitAddress = substring_index(OwnerAddress, ',', 1),
OwnerSplitCity = substring_index(substring_index(OwnerAddress, ',', 2), ',' , -1)
;
-- SoldAsVacant
update nashvillehousing
set SoldAsVacant = 
case when SoldAsVacant = 'N' then 'No' 
when SoldAsVacant = 'No' then 'No' 
else 'Yes' end
;
-- remove diplicates
create temporary table sub 
select *, 
row_number() over (partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference order by UniqueID) as RowNumber
from nashvillehousing
;
delete
from sub
where RowNumber > 1
;
-- delete unused columns
alter table nashvillehousing
drop OwnerAddress, 
drop TaxDistrict, 
drop PropertyAddress
;

