# Note: 0 is 0dB, 1000 means 27dB, 1000 exp means 1ms, 5000 means 5ms, and 12000 means 12ms.


# Commands used to control settings of cameras
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=12000

v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam1 --set-ctrl=exposure_time_absolute=12000



v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=12000

v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam0 --set-ctrl=exposure_time_absolute=12000




v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=0
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=12000

v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=1000

v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=5000

v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=gain=1000
v4l2-ctl -d /dev/uvc/cam3 --set-ctrl=exposure_time_absolute=12000


# Image names and parameters
pano_cam0_left:
1730122133150_cam_1 -> gain = 0dB / exposure = 1ms
1730122140534_cam_1 -> gain = 0dB / exposure = 5ms
1730122148257_cam_1 -> gain = 0dB / exposure = 12ms
1730122155992_cam_1 -> gain = 27dB / exposure = 1ms
1730122163570_cam_1 -> gain = 27dB / exposure = 5ms
1730122172060_cam_1 -> gain = 27dB / exposure = 12ms

pano_cam1_front:
1730121993163_cam_5 -> gain = 0dB / exposure = 1ms
1730122006015_cam_5 -> gain = 0dB / exposure = 5ms
1730122018124_cam_5 -> gain = 0dB / exposure = 12ms
1730122036505_cam_5 -> gain = 27dB / exposure = 1ms
1730122043911_cam_5 -> gain = 27dB / exposure = 5ms
1730122055312_cam_5 -> gain = 27dB / exposure = 12ms

pano_cam3_back:
1730122262618_cam_0 -> gain = 0dB / exposure = 1ms
1730122272944_cam_0 -> gain = 0dB / exposure = 5ms
1730122283608_cam_0 -> gain = 0dB / exposure = 12ms
1730122302949_cam_0 -> gain = 27dB / exposure = 1ms
1730122311451_cam_0 -> gain = 27dB / exposure = 5ms
1730122319543_cam_0 -> gain = 27dB / exposure = 12ms

# Suggestion for experiments in matlab:
run 1 -> process 3 images with gain 0dB together
run 2 -> process 3 images with gain 27dB together
run 3 -> process all 6 images together

repeat above for the 3 cameras, once for with white balance (wb folders) and without white balance (no_wb folders)

Results should show:
1) HDR generates better images
2) We have an idea of processing time per image
3) Does more noise effect the results somehow? (note: More gain leads to more noise)

# Caution: We work with different standard for naming the cameras, which can lead to a bit of confusion. Consider the name of the folders: pano_cam0_left, pano_cam1_front, and pano_cam3_back.
