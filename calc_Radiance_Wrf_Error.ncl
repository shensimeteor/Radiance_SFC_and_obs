load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "read_obs_radiance_txt.ncl"

begin

 if (.not. isvar("file_in")) then
     print(" ")
     print(" You did not define the input file --> EXIT")
     exit
 end if

 if(.not. isvar("obs_txt_file")) then
     print(" ")
     print(" You did not define the obs_txt_file  --> EXIT")
     exit
 end if

 f=addfile(file_in+".nc", "r")
 var=f->SWDOWN
 shp=dimsizes(var)
 ny=shp(1)
 nx=shp(2)

 obs_rad=read_obs_radiance_txt(obs_txt_file, 6)
 opt=True
 opt@returnInt = True
 pos=wrf_user_ll_to_ij(f, obs_rad@lons, obs_rad@lats, opt)
 idx = pos -1 
 npt=dimsizes(obs_rad)
 wrf_value = new((/npt/), "float")
 wrf_value@_FillValue = 999999.0
 do i=0,npt-1
     if(idx(0,i) .ge. nx .or. idx(0,i) .lt. 0 .or. idx(1,i) .ge. ny .or. idx(1,i) .lt. 0) then
         print("i="+i+", lon="+obs_rad@lons(i)+", lat="+obs_rad@lats(i)+": outside domain: ("+idx(0,i)+","+idx(1,i)+"), fill missing!")
         wrf_value(i) = wrf_value@_FillValue
     else
         wrf_value(i) = var(0, idx(1,i), idx(0,i))
     end if
 end do
 diff_value = wrf_value - obs_rad

 ;write out
 title="stnid, lons, lats, obs_rad, wrf_rad, error_rad"
 lines=new((/npt+1/), "string")
 lines(0)=title
 do i=0, npt-1
     lines(i+1) = obs_rad@stnids(i) + sprintf(",%8.3f", obs_rad@lons(i)) + sprintf(",%8.3f", obs_rad@lats(i)) + \
                sprintf(",%8.2f", obs_rad(i))+sprintf(",%8.2f", wrf_value(i)) + sprintf(",%8.2f", diff_value(i))
 end do
 asciiwrite("output.txt", lines)
end
