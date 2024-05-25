# Nippers

Nippers is a multimedia file cutter script that cuts the provided multimedia file into pieces of the same format, using the provided config file as the time and naming guide.

## Usage

Example of use:

1. Create a `config.txt` file with the following structure:
   ```
   00:00 Entering the void
   03:15 Warm abyss
   06:11 ---
   07:21 The end
   ```

2. Run the script `nippers.sh` with the following command:
   ```sh
   $ nippers.sh -i /mnt/music/void.avi -c ./config.txt -o /mnt/music/Void
   ```

### Output
After running the script, the output will display the extraction of the multimedia file into individual pieces based on the config file. For example:
```
- Extracting: "Entering the void"
  - Time info: 0 + 195 s
- Extracting: "Warm abyss"
  - Time info: 195 + 154 s
- Skipping:
  - Time info: 394 + 92 s
- Extracting: "04. Everything_s Alright"
  - Time info: 441 + 110 s
```

### Result
After the script execution, you can find the extracted multimedia files in the specified output directory. For example:
```sh
$ ls /mnt/music/Void
'Entering the void.avi' 'Warm abyss.avi' 'The end.avi'
```

## License
The project is licensed under LGPL3 or later
