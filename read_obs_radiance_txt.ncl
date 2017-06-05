
undef("read_obs_radiance_txt")
;return: total_radiance, @lons, @lats, @_FillValue, @elevs, @stnids
function read_obs_radiance_txt(file_name: string, icol_to_read: integer)
local strs, n_str, npt, total_radiance, items
begin
    strs=asciiread(file_name, -1, "string")
    n_str=dimsizes(strs)
    npt=n_str - 2
    total_radiance=new((/npt/), "float")
    total_radiance@lons=new((/npt/), "float")
    total_radiance@lats=new((/npt/), "float")
    total_radiance@elevs=new((/npt/), "float")
    total_radiance@stnids=new((/npt/), "string")
    total_radiance@_FillValue=999999
    print(icol_to_read)
    do ipt=0, npt-1
        items=str_split(strs(ipt+2), " ")
        total_radiance(ipt) = tofloat(items(icol_to_read))
        total_radiance@lons(ipt) = tofloat(items(4))
        total_radiance@lats(ipt) = tofloat(items(3))
        total_radiance@elevs(ipt) = tofloat(items(5))
        total_radiance@stnids(ipt) = items(2)
        delete(items)
    end do
    return(total_radiance)
end



