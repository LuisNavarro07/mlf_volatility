*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: February 2024
/// Script: Profile Do File
*************************************************************************
*************************************************************************
/// Municipal Liquidity Facility
**** Set Command Directory
clear all
graph drop _all 
// Set Work Environment 
*cd "C:\Users\luise\OneDrive - Indiana University\Research\MLF_Volatility"
cd "/Users/luisenriquenavarro/Library/CloudStorage/OneDrive-IndianaUniversity/Research/MLF_Volatility/"

glo  cod "0_Script/"
glo  raw "1_Data/Raw/"
glo  cln "1_Data/Clean/"
glo  oup "2_Output/res_out"
glo  log "3_Logs/"
glo  tem "1_Data/Temp/"

global dt : di %tdDNCY daily("$S_DATE", "DMY")
di "$dt"

/*
global bi "build\input"
global bt "build\temp"
global bo "build\output"
global raw "1_Data\Raw"

global ai "1_Data\Clean"
global at "analysis\temp"
global ao "analysis\output"
global ac "analysis\code"
*/

set scheme s1color
graph set window fontface "Times New Roman"
global export replace 
