createuser gvm
createdb -O gvm gvmd

dir=$1


psql -d gvmd -f "$dir/postgres.sql"
exit
