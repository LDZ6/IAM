#!/bin/bash


: << EOF
API 性能测试脚本，会自动执行 wrk 命令，采集数据、分析数据并调用 gnuplot 画图

使用方式 ( 测试 API 性能)�?1. 启动 iam-apiserver(8080端口)
2. 执行测试脚本: ./wrktest.sh

脚本会生�?.dat 的数据文件，每列含义为：并发�?QPS 平均响应时间 成功�?
使用方式 (对比2次测试结�?
1. 性能测试�?/wrktest.sh iam-apiserver http://127.0.0.1:8080/healthz
2. 执行命令�?./wrktest.sh diff apiserver.dat http.dat

> Note: 需要确保系统安装了 wrk �?gnuplot 工具
EOF

iamroot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
wrkdir="${iamroot}/_output/wrk"
jobname="apiserver"
duration="300s"
threads=$((3 * `grep -c processor /proc/cpuinfo`))

source "${iamroot}/scripts/lib/color.sh"

# Set wrk options
iam::wrk::setup() {
  #concurrent="200 500 1000 3000 5000 10000 15000 20000 25000 50000 100000 200000 500000 1000000"
  concurrent="200 500 1000 3000 5000 10000 15000 20000 25000 50000"
  cmd="wrk -t${threads} -d${duration} -T30s --latency"
}

# Print usage infomation
iam::wrk::usage()
{
  cat << EOF

Usage: $0 [OPTION] [diff] URL
Performance automation test script.

  URL                    HTTP request url, like: http://127.0.0.1:8080/healthz
  diff                   Compare two performance test results

OPTIONS:
  -h                     Usage information
  -n                     Performance test task name, default: apiserver
  -d                     Directory used to store performance data and gnuplot graphic, default: _output/wrk

Reprot bugs to <colin404@foxmail.com>.
EOF
}

# Convert plot data to useable data
function iam::wrk::convert_plot_data()
{
  echo "$1" | awk -v datfile="${wrkdir}/${datfile}" ' {
  if ($0 ~ "Running") {
    common_time=$2
  }
if ($0 ~ "connections") {
  connections=$4
  common_threads=$1
}
if ($0 ~ "Latency   ") {
  avg_latency=convertLatency($2)
}
if ($0 ~ "50%") {
  p50=convertLatency($2)
}
if ($0 ~ "75%") {
  p75=convertLatency($2)
}
if ($0 ~ "90%") {
  p90=convertLatency($2)
}
if ($0 ~ "99%") {
  p99=convertLatency($2)
}
if ($0 ~ "Requests/sec") {
  qps=$2
}
if ($0 ~ "requests in") {
  allrequest=$1
}
if ($0 ~ "Socket errors") {
  err=$4+$6+$8+$10
}
}
END {
rate=sprintf("%.2f", (allrequest-err)*100/allrequest)
print connections,qps,avg_latency,rate >> datfile
}

function convertLatency(s) {
  if (s ~ "us") {
    sub("us", "", s)
    return s/1000
  }
if (s ~ "ms") {
  sub("ms", "", s)
  return s
}
if (s ~ "s") {
  sub("s", "", s)
  return s * 1000
}
}'
}

# Remove existing data file
function iam::wrk::prepare()
{
  rm -f ${wrkdir}/${datfile}
}

# Plot according to gunplot data file
function iam::wrk::plot() {
  gnuplot <<  EOF
set terminal png enhanced #输出格式为png文件
set ylabel 'QPS'
set xlabel 'Concurrent'
set y2label 'Average Latency (ms)'
set key top left vertical noreverse spacing 1.2 box
set tics out nomirror
set border 3 front
set style line 1 linecolor rgb '#00ff00' linewidth 2 linetype 3 pointtype 2
set style line 2 linecolor rgb '#ff0000' linewidth 1 linetype 3 pointtype 2
set style data linespoints

set grid #显示网格
set xtics nomirror rotate #by 90#只需要一个x�?set mxtics 5
set mytics 5 #可以增加分刻�?set ytics nomirror
set y2tics

set autoscale  y
set autoscale y2

set output "${wrkdir}/${qpsttlb}"  #指定数据文件名称
set title "QPS & TTLB\nRunning: ${duration}\nThreads: ${threads}"
plot "${wrkdir}/${datfile}" using 2:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#EE0000" axis x1y1 t "QPS","${wrkdir}/${datfile}" using 3:xticlabels(1) w lp pt 5 ps 1 lc rgbcolor "#0000CD" axis x2y2 t "Avg Latency (ms)"

unset y2tics
unset y2label
set ytics nomirror
set yrange[0:100]
set output "${wrkdir}/${successrate}"  #指定数据文件名称
set title "Success Rate\nRunning: ${duration}\nThreads: ${threads}"
plot "${wrkdir}/${datfile}" using 4:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#F62817" t "Success Rate"
EOF
}

# Plot diff graphic
function iam::wrk::plot_diff()
{
  gnuplot <<  EOF
set terminal png enhanced #输出格式为png文件
set xlabel 'Concurrent'
set ylabel 'QPS'
set y2label 'Average Latency (ms)'
set key below left vertical noreverse spacing 1.2 box autotitle columnheader
set tics out nomirror
set border 3 front
set style line 1 linecolor rgb '#00ff00' linewidth 2 linetype 3 pointtype 2
set style line 2 linecolor rgb '#ff0000' linewidth 1 linetype 3 pointtype 2
set style data linespoints

#set border 3 lt 3 lw 2   #这会让你的坐标图的border更好�?set grid #显示网格
set xtics nomirror rotate #by 90#只需要一个x�?set mxtics 5
set mytics 5 #可以增加分刻�?set ytics nomirror
set y2tics

#set pointsize 0.4 #点的像素大小
#set datafile separator '\t' #数据文件的字段用\t分开

set autoscale  y
set autoscale y2

#设置图像的大�?为标准大小的2�?#set size 2.3,2

set output "${wrkdir}/${t1}_${t2}.qps.ttlb.diff.png"  #指定数据文件名称
set title "QPS & TTLB\nRunning: ${duration}\nThreads: ${threads}"
plot "/tmp/plot_diff.dat" using 2:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#EE0000" axis x1y1 t "${t1} QPS","/tmp/plot_diff.dat" using 5:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#EE82EE" axis x1y1 t "${t2} QPS","/tmp/plot_diff.dat" using 3:xticlabels(1) w lp pt 5 ps 1 lc rgbcolor "#0000CD" axis x2y2 t "${t1} Avg Latency (ms)", "/tmp/plot_diff.dat" using 6:xticlabels(1) w lp pt 5 ps 1 lc rgbcolor "#6495ED" axis x2y2 t "${t2} Avg Latency (ms)"

unset y2tics
unset y2label
set ytics nomirror
set yrange[0:100]
set output "${wrkdir}/${t1}_${t2}.successrate.diff.png"  #指定数据文件名称
set title "Success Rate\nRunning: ${duration}\nThreads: ${threads}"
plot "/tmp/plot_diff.dat" using 4:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#EE0000" t "${t1} Success Rate","/tmp/plot_diff.dat" using 7:xticlabels(1) w lp pt 7 ps 1 lc rgbcolor "#EE82EE" t "${t2} Success Rate"
EOF
}

# Start API performance testing
iam::wrk::start_performance_test() {
  iam::wrk::prepare

  for c in ${concurrent}
  do
    wrkcmd="${cmd} -c ${c} $1"
    echo "Running wrk command: ${wrkcmd}"
    result=`eval ${wrkcmd}`
    iam::wrk::convert_plot_data "${result}"
  done

  echo -e "\nNow plot according to ${COLOR_MAGENTA}${wrkdir}/${datfile}${COLOR_NORMAL}"
  iam::wrk::plot &> /dev/null
  echo -e "QPS graphic file is: ${COLOR_MAGENTA}${wrkdir}/${qpsttlb}${COLOR_NORMAL}
Success rate graphic file is: ${COLOR_MAGENTA}${wrkdir}/${successrate}${COLOR_NORMAL}"
}

while getopts "hd:n:" opt;do
  case ${opt} in
    d)
      wrkdir=${OPTARG}
      ;;
    n)
      jobname=${OPTARG}
      ;;
    ?)
      iam::wrk::usage
      exit 0
      ;;
  esac
done

shift $(($OPTIND-1))

mkdir -p ${wrkdir}
case $1 in
  "diff")
    if [ "$#" -lt 3 ];then
      iam::wrk::usage
      exit 0
    fi

    t1=$(basename $2|sed 's/.dat//g') # 对比图中红色线条名称
    t2=$(basename $3|sed 's/.dat//g') # 对比图中粉色线条名称

    join $2 $3 > /tmp/plot_diff.dat
    iam::wrk::plot_diff `basename $2` `basename $3`
    exit 0
    ;;
  *)
    if [ "$#" -lt 1 ];then
      iam::wrk::usage
      exit 0
    fi
    url="$1"

    qpsttlb="${jobname}_qps_ttlb.png"
    successrate="${jobname}_successrate.png"
    datfile="${jobname}.dat"

    iam::wrk::setup
    iam::wrk::start_performance_test "${url}"
    ;;
esac
