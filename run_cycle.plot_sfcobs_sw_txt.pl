#!/usr/bin/perl

$GMID="GECN3KM";
$MEMBER="GFS_WCTRL";
$CYCLE="2017051012";
$start_hour=0;
$end_hour=72;
$incre_hour=1;
$dom=2;

$HOMEDIR=$ENV{HOME};
$GMODDIR="$HOMEDIR/data/GMODJOBS/$GMID";
$ENSPROCS="$ENV{CSH_ARCHIVE}/ncl";
$RUNDIR="$HOMEDIR/data/cycles/$GMID/$MEMBER/";
$ARCDIR="$HOMEDIR/data/cycles/$GMID/archive/$MEMBER/"; #aux_$CYCLE
$OBSDIR="$HOMEDIR/sishen/Radiance_Plot/Radiation/";
$WORKDIR="/dev/shm/ObsRadiancePlot/$GMID/$MEMBER";
$SCRIPT_DIR="$HOMEDIR/sishen/Radiance_Plot/";
$TEMPDIR="$SCRIPT_DIR/temp_aux/$CYCLE"; #save aux.nc file
$PLOTDIR="$SCRIPT_DIR/output_png/$CYCLE";
system("test -d $PLOTDIR || mkdir -p $PLOTDIR");
require "$ENSPROCS/common_tools.pl";

for ($hr=$start_hour; $hr <=$end_hour; $hr=$hr+$incre_hour) {
    $d=&tool_date12_add("${CYCLE}00", $hr, "hour");
    $bjd=&tool_date12_add($d, 8, "hour");
    $mywork="$WORKDIR/$CYCLE/$d/";
    system("test -d $mywork || mkdir -p $mywork");
    chdir($mywork);
    #cp aux
    $file_name2_nc3=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc");
    $file_temp_save="$TEMPDIR/$file_name2_nc3";
    if( -e $file_name2_nc3) {
        print "file exists in /dev/shm\n";
        if( !-e $file_temp_save) { 
            system("cp -r $file_name2_nc3 $TEMPDIR/");
        }
    }elsif (-e $file_temp_save) { 
        system("cp -r $file_temp_save $mywork/");
    }else {
        $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4.p");
        $file_path2="$ARCDIR/aux3_$CYCLE/$file_name2";
        system("cp $file_path2 $mywork/");
        $file_name2_unpack=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4");
        print("doing ncpdq unpacking..\n");
        system("ncpdq -O -U $file_name2 $file_name2_unpack && rm -rf $file_name2");
        print("doing nc4 to nc3..\n");
        system("ncks -O -3 $file_name2_unpack $file_name2_nc3");
        system(" test -d $TEMPDIR || mkdir -p $TEMPDIR");
        system("cp $file_name2_nc3 $TEMPDIR/");
    }
    $file_path="$mywork/$file_name2_nc3";
    #cp obsfile
    $obs_file="$OBSDIR/${bjd}_Radiation.txt";
    system("cp $obs_file $mywork");
    print("$obs_file\n");
    #ln ncl
    symlink("$SCRIPT_DIR/plot_SFC_and_obs_SW_txt.ncl", "plot_SFC_and_obs_SW_txt.ncl");
    symlink("$SCRIPT_DIR/read_obs_radiance_txt.ncl", "read_obs_radiance_txt.ncl");
    #run ncl
    $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' plot_SFC_and_obs_SW_txt.ncl > log.ncl);
    print($cmd."\n");
    system($cmd);
    #cpout png & rm workdir
    system("cp 20*/*png $PLOTDIR/${d}_d2_swdown.png");
    chdir("$WORKDIR/$CYCLE");
    system("rm -rf $mywork");
}





