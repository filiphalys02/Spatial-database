  1:250 000 Scale Colour Raster

  Notes on the Supply of Ordnance Survey Digital Data 
  ---------------------------------------------------
  Directory Structure 
  --------------------

   This information is made up of 3 sections, containing examples:

   o  SECTION ONE - HIGH LEVEL STRUCTURE EXAMPLE
   o  SECTION TWO - CONTENTS
   o  SECTION THREE - DIRECTORY STRUCTURE EXAMPLE
   
   

   -------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------

   -----------
   SECTION ONE   
   -----------

   SECTION ONE - HIGH LEVEL STRUCTURE EXAMPLE


   The directory structure of the data is shown below:


   
                           ROOT 
                             |
          ----------------------------------------
         |                   |                   |
      DOCUMENTS           GAZETTEER             DATA



   -------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------

   -----------
   SECTION TWO   
   -----------

   SECTION TWO CONTENTS

   
   ROOT
     |
     |--DOCUMENTS
     |   |--250K_LEGEND_YYYY.tif
     |   |--250K_LEGEND_YYYY.pdf
     |   |--250K_RELEASE_YYYY_CHANGE.txt
     |   |--250K_TILE_LIST.txt
     |   |--LICENCE.txt
     |   
     |
     |--GAZETTEER
     |-- DATA     
     |   |--250K_RASTER_GAZ_YYYY.txt
     |
     |-- DATA
     |   |--DATA   
     |             
     |--README.txt



   
   Directories may contain additional documentation specific to that supply.
   

   -------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------

   -------------
   SECTION THREE   
   -------------

   SECTION THREE – DIRECTORY STRUCTURE EXAMPLE

   3a - ROOT Directory
   3b - DOCUMENTS Directory
   3c - GAZETTEER Directory
   3d - DATA Directory



   3a  ROOT Directory
   ------------------
   The ROOT directory will contain the following directories:
       o DOCUMENTS
       o GAZETTEER
       o DATA

   The ROOT directory will also contain the following ASCII text file:
       o This file - README.txt

   Directories may contain additional documentation specific to that supply.



   3b  DOCUMENTS Directory
   -----------------
   Below are the types of documents contained within the DOC directory. 

   o 250K_LEGEND_YYYY.pdf       - contains a sample legend
   o 250K_LEGEND_YYYY.tif       - contains a sample legend
   o 250K_RELEASE_YYYY_CHANGE.txt - contains information relating to the product 
                                    changes associated with that release.
   o 250K_TILE_LIST.txt           - a list of tiles that the media contains. 
   o LICENCE.txt                  - contains information relating to your Licence. 
    

   The DOCUMENTS directory may contain additional documentation specific to that supply.



   3c  GAZETTEER Directory
   -----------------------
   The GAZETTEER directory will contain the Gazetteer data (250K_RASTER_GAZ_YYYY.txt) 
   within a DATA sub-directory.  The Data is National Coverage in an ASCII text format. The structure will appear as 
   follows:

   ROOT
    |
    |--GAZETTEER
    |-- DATA
        |--250K_RASTER_GAZ_YYYY.txt

   The GAZETTEER directory files may contain additional information in the file name 
   specific to that supply.  Where YYYY refers to the year.



   3d DATA Directory
   ----------------------

   The data directory will contain the data files.   

    ROOT
     |
     |-- DATA
         |--...(.tif files)




   -------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------

  
   --------------------------------------------------------
   README FILE CREATED BY ORDNANCE SURVEY, © June 2023
   --------------------------------------------------------
   V1.1


