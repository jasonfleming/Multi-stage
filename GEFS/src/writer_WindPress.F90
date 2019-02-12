!                 subroutine of genOWI.F90
!                  Part of Multistage tool
!
! -----------------------------------------------------------------
! Function:
!    Using the calculated ensemble mean and std in 
!    matrix ave_std to write three fort.222s (wind) and
!    three fort.221s (pressure)
! -----------------------------------------------------------------
!
 subroutine writer_WindPress(starttime,endtime,num_cell_corners,output_snap_num,iLat,iLon,dx,dy,swlat,swlong,ave_std,temp_freq,stat)
  !
  character(len=15), intent(in) ::  starttime, endtime
  character(len=5), intent(out) ::  stat
  integer, intent(in)           ::  iLat, iLon
  real, intent(in)              ::  dx, dy
  real, intent(in)              ::  swlat, swlong
  real                          ::  sw
  integer, intent(in)           ::  temp_freq
  integer                       ::  hr
  integer                       ::  i, j, k
  integer, intent(in)           ::  output_snap_num, num_cell_corners
  real, dimension(10000000,12), intent(in)   ::  ave_std 
  !
  ! Writing fort.222s: (1)ave  (2)ave+std  (3)ave-std  
10 format(i9,i10,f9.4,f9.4,f14.4,f14.4,t68,A10,i3)
11 format (8f10.4)
  !
  j=1
  hr=0    ! Indicates the frcst hr since starttime 
  !
  !  fort.2220 => wind ensemble mean
  !  fort.2221 => wind ensemble mean+std_uv
  !  fort.2222 => wind ensemble mean-std_uv
  !  fort.2230 => pres ensemble mean
  !  fort.2231 => pres ensemble mean+std_p
  !  fort.2232 => pres ensemble mean-std_p
  !
  ! Header: starttime and endtime (wind)
  write(2220,'(t56,A10,t71,A10)') starttime , endtime
  write(2221,'(t56,A10,t71,A10)') starttime , endtime
  write(2222,'(t56,A10,t71,A10)') starttime , endtime
  ! Header: starttime and endtime (pressure)
  write(2230,'(t56,A10,t71,A10)') starttime , endtime
  write(2231,'(t56,A10,t71,A10)') starttime , endtime
  write(2232,'(t56,A10,t71,A10)') starttime , endtime
  !
  ! swlong is in 0-360 degree format
  ! We need 0-180 to define east, and -180-0 to define west
  ! So, we subtract 360 from swlong to get above format:
  ! Example: swlong=279, 360-279=-81
  sw=swlong-360
  do k=1,output_snap_num
     !
     ! HEADERS
     ! E N S E M B L E    A V E R A G E 
     write(2220,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr
     ! E N S E M B L E    A V E R A G E + STD
     write(2221,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr
     ! E N S E M B L E    A V E R A G E - S
     write(2222,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr

     ! U component
     ! E N S E M B L E    A V E R A G E
     write(2220,11) (ave_std(i,1),i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E + STD
     write(2221,11) (ave_std(i,7),i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E - STD
     write(2222,11) (ave_std(i,10),i=j,num_cell_corners+(j-1),1)

     ! V component
     ! E N S E M B L E    A V E R A G E
     write(2220,11) (ave_std(i,2),i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E
     write(2221,11) (ave_std(i,8),i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E
     write(2222,11) (ave_std(i,11),i=j,num_cell_corners+(j-1),1)

     j  = j  + num_cell_corners
     hr = hr + temp_freq
  enddo
!
  j=1
  hr=0
  do k=1,output_snap_num
     !
     ! HEADERS
     ! E N S E M B L E    A V E R A G E
     write(2230,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr
     ! E N S E M B L E    A V E R A G E + STD
     write(2231,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr
     ! E N S E M B L E    A V E R A G E - STD
     write(2232,10) iLat,iLon,dx,dy,swlat,sw,starttime,hr

     ! Press component
     ! E N S E M B L E    A V E R A G E
     write(2230,11) (ave_std(i,3 )/100,i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E + STD
     write(2231,11) (ave_std(i,9 )/100,i=j,num_cell_corners+(j-1),1)
     ! E N S E M B L E    A V E R A G E - STD
     write(2232,11) (ave_std(i,12)/100,i=j,num_cell_corners+(j-1),1)

     j  = j  + num_cell_corners
     hr = hr + temp_freq
  enddo
! 
  stat="success"
  return
  end subroutine
