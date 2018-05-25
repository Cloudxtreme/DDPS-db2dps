:

# from
# var = value
# var = _var_

file=$1

awk '{

	if ($1 ~ /#/) { print $0; next }
	if ($2 == "=") {
		var = $1
		value = $1
		gsub(/.*:/, "", value)
		print var " = __" value "__"  ; next
	}
	else
	{
		print $0;
		next

	}

}' $file > ${file}.new

/bin/mv ${file}.new ${file}

