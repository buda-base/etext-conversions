@echo on

for /D %%w in (*) do (
	for /D %%v in (%%w\rtfs\*) do (
	  for %%f in (%%v\*.rtf) do (
		c:\unicdocp\udp.exe -x rtf %%f
	  )
	)
)
