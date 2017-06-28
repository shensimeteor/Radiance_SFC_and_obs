#!/usr/bin/perl

$GMID="GECN3KM";
$MEMBER="GFS_WCTRL";
$CYCLE="2017060412";
$start_hour=-6;
$end_hour=72;
$incre_hour=1;
$dom=2;
$do_save=0; #do or don't save aux files on disk

$HOMEDIR=$ENV{HOME};
$GMODDIR="$HOMEDIR/data/GMODJOBS/$GMID";
$ENSPROCS="$ENV{CSH_ARCHIVE}/ncl";
$RUNDIR="$HOMEDIR/data/cycles/$GMID/$MEMBER/";
$ARCDIR="$HOMEDIR/data/cycles/$GMID/archive/$MEMBER/"; #aux_$CYCLE
$OBSDIR="$HOMEDIR/sishen/Radiance_Plot/Radiation_date_adjusted/";
$WORKDIR="/dev/shm/ObsRadiancePlot/$GMID/$MEMBER";
$SCRIPT_DIR="$HOMEDIR/sishen/Radiance_Plot/";
$TEMPDIR="$SCRIPT_DIR/temp_aux/$CYCLE"; #save aux.nc file
$PLOTDIR="$SCRIPT_DIR/output_png/$CYCLE";
system("test -d $PLOTDIR || mkdir -p $PLOTDIR");
require "$ENSPROCS/common_tools.pl";

for ($hr=$start_hour; $hr <=$end_hour; $hr=$hr+$incre_hour) {
    $d=&tool_date12_add("${CYCLE}00", $hr, "hour");
    print("to process $d -----\n");
    $bjd=$d;
    if($hr < 0){
        $end="_F";
    }else{
        $end="_P";
    }
    $mywork="$WORKDIR/$CYCLE/$d/";
    system("test -d $mywork || mkdir -p $mywork");
    chdir($mywork);
    #cp aux
    $file_name2_nc3=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc");
    $file_temp_save="$TEMPDIR/$file_name2_nc3";
    if( -e $file_name2_nc3) {
        print "file exists in /dev/shm\n";
        if( !-e $file_temp_save && $do_save ) { 
            system("cp -r $file_name2_nc3 $TEMPDIR/");
        }
    }elsif (-e $file_temp_save) { 
        print "file exists in temp dir, to cp\n";
        system("cp -r $file_temp_save $mywork/");
    }else{
        if( $hr < 0) {
            $file_name1=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", "");
            $file_path1="$RUNDIR/$CYCLE/WRF_F/$file_name1";
            $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc4.p");
            $file_path2="$ARCDIR/aux3_final/$file_name2";
        }else{
            $file_name1=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", "");
            $file_path1="$RUNDIR/$CYCLE/WRF_P/$file_name1";
            $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc4.p");
            $file_path2="$ARCDIR/aux3_$CYCLE/$file_name2";
        }
        if( -e $file_path1) {
            print("file exists in WRF_F/WRF_P run dir, to cp\n");
            system("cp -r $file_path1 $mywork/$file_name2_nc3");
        }elsif (-e $file_path2) {
            print("file exists in aux archive dir, to cp\n");
            system("cp -r $file_path2 $mywork/");
            $file_name2_unpack=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4");
            print("doing ncpdq unpacking..\n");
            system("ncpdq -O -U $file_name2 $file_name2_unpack && rm -rf $file_name2");
            print("doing nc4 to nc3..\n");
            system("ncks -O -3 $file_name2_unpack $file_name2_nc3");
            if( $do_save) {
                system("cp $file_name2_nc3 $TEMPDIR/");
            }
        }else {
            print("WARN: aux file not found , next \n");
            next;
        }
    }
    $file_path="$mywork/$file_name2_nc3";
    #cp obsfile
    $obs_file="$OBSDIR/${bjd}_Radiation.txt";
    if( ! -e $obs_file ) {
        print("WARN: $obs_file not found, next \n");
        next;
    }
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

