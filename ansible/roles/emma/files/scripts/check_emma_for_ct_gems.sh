#!/bin/bash

ERR=0
emmadir=/data/private/share/emma/core/vendor/cache

for ruby in 1.8 1.9.1
do
   gemdir="/opt/ruby-${ruby}/lib/ruby/gems/${ruby}/gems/"
   cd ${gemdir}
   for gem in *
   do
      num=$(echo $gem | cut -d. -f4)
      # How do we check its one of ours by making an assumption that the SVN number is > 1000 and is the 4th field
      # e.g. activerecord-rdbcp-adapter-1.0.0.30685.gem
      if [ -n "${num}" ]; then
      # check for integer next...
         if [ ${num} -eq ${num} ] 2>/dev/null; then
            # check for large integer (svn commit) and file existence
            if [ -f ${emmadir}/${gem}.gem -a ${num} -gt 2500 ]; then
               echo "Error: CT gem file ${gem}.gem in ruby ${ruby} is also in Emma vendor cache"
               ERR=1
            fi
         fi
      fi

   done

done

exit ${ERR}
  
# eof
