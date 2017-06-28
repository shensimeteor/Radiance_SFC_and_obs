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
 wrf_varnames=(/"SWDOWN", "SWDDIR", "SWDDNI", "SWDDIF"/)
 nwrf=dimsizes(wrf_varnames)
 obs_colidx=(/6,7,8,9,10,11/)
 obs_colname=(/"V14311", "V14312", "V14313", "V14314", "V14315", "V14316"/)
 nobs=dimsizes(obs_colidx)
 
 obs_rad=read_obs_radiance_txt(obs_txt_file, 6) ; for lon,lat
 npt=dimsizes(obs_rad)
 wrf_points_val = new((/nwrf, npt/), "float")
 missing_value = 999999.0
 wrf_points_val@_FillValue = missing_value
 obs_points_val = new((/nobs, npt/), "float")
 obs_points_val@_FillValue = missing_value
 ;get WRF vars value on points
 do ivar=0, nwrf-1
     var=f->$wrf_varnames(ivar)$
     shp=dimsizes(var)
     ny=shp(1)
     nx=shp(2)

     opt=True
     opt@returnInt = True
     pos=wrf_user_ll_to_ij(f, obs_rad@lons, obs_rad@lats, opt)
     idx = pos -1 
     npt=dimsizes(obs_rad)
     wrf_value = new((/npt/), "float")
     wrf_value@_FillValue = missing_value
     do i=0,npt-1
         if(idx(0,i) .ge. nx .or. idx(0,i) .lt. 0 .or. idx(1,i) .ge. ny .or. idx(1,i) .lt. 0) then
             print("i="+i+", lon="+obs_rad@lons(i)+", lat="+obs_rad@lats(i)+": outside domain: ("+idx(0,i)+","+idx(1,i)+"), fill missing!")
             wrf_value(i) = wrf_value@_FillValue
         else
             wrf_value(i) = var(0, idx(1,i), idx(0,i))
         end if
     end do
     wrf_points_val(ivar,:) = wrf_value
 end do

 ;get OBS all column values
 do i=0, nobs-1
    obs_rad=read_obs_radiance_txt(obs_txt_file, obs_colidx(i)) ; for lon,lat
    obs_points_val(i,:) = obs_rad
 end do

 ;write out
 title="stnid, lons, lats, "+str_join(wrf_varnames, ",")+","+str_join(obs_colname,",")
 lines=new((/npt+1/), "string")
 lines(0)=title
 do i=0, npt-1
     str_wrf = str_join(sprintf("%9.2f", wrf_points_val(:,i)), ",")
     str_obs = str_join(sprintf("%9.2f", obs_points_val(:,i)), ",")
     lines(i+1) = obs_rad@stnids(i) + sprintf(",%8.3f", obs_rad@lons(i)) + sprintf(",%8.3f,", obs_rad@lats(i)) + \
                str_wrf+","+str_obs
 end do
 asciiwrite("output_wrfobs.txt", lines)
end
