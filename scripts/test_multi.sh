cd ..
#RUN='konsole --noclose -e /home/adomurad/sources/moai-game/run.sh'
RUN='/home/adomurad/sources/moai-game/run.sh'
for i in {1..3}; do
    IP='localhost' CLIENT=1 TEST_KNIGHT=1 $RUN &
done

SERVER=1 TEST_KNIGHT=1 $RUN
