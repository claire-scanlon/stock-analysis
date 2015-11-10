import mpi.MPI;
import mpi.MPIException;
import mpi.MpiOps;
import org.apache.commons.cli.*;
import org.apache.commons.io.FilenameUtils;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * Run heatmap generation in parallel in multiple machines
 * This is a data parallel application
 */
public class DSHeatMapGenerator {
    private boolean mpi;
    private String pointFolder;
    private String distanceFolder;
    private MpiOps mpiOps;
    private String configFile;
    private String outDir;

    public DSHeatMapGenerator(boolean mpi, String pointFolder, String distanceFolder, String configFile, String outDir) {
        this.mpi = mpi;
        this.pointFolder = pointFolder;
        this.configFile = configFile;
        this.distanceFolder = distanceFolder;
        this.outDir = outDir;
    }

    public static void main(String[] args) {
        Options options = new Options();
        options.addOption("p", true, "Point folder");
        options.addOption("d", true, "Distance matrix folder");
        options.addOption("m", false, "mpi");
        options.addOption("c", true, "Config file");
        options.addOption("o", true, "Out Dir");

        CommandLineParser commandLineParser = new BasicParser();
        try {
            CommandLine cmd = commandLineParser.parse(options, args);
            String  _vectorFile = cmd.getOptionValue("p");
            String _distFile = cmd.getOptionValue("d");
            boolean mpi = cmd.hasOption("m");
            String configFile = cmd.getOptionValue("c");
            String outDir = cmd.getOptionValue("o");
            String print = "point: " + _vectorFile + " ,distance matrix folder: "
                    + _distFile;
            System.out.println(print);
            if (mpi) {
                MPI.Init(args);
            }
            DSHeatMapGenerator dsHeatMapGenerator = new DSHeatMapGenerator(mpi, _vectorFile, _distFile, configFile, outDir);
            dsHeatMapGenerator.process();
            if (mpi) {
                MPI.Finalize();
            }
        } catch (MPIException | ParseException e) {
            System.out.println(options.toString());
        }
    }

    public void process() {
        System.out.println("Starting HeatMap calculator...");
        File pointInFolder = new File(pointFolder);
        if (!pointInFolder.isDirectory()) {
            System.out.println("Point must be a folder: " + pointFolder);
            return;
        }

        File distanceInFolder = new File(distanceFolder);
        if (!distanceInFolder.isDirectory()) {
            System.out.println("Distance must be a folder: " + distanceFolder);
            return;
        }

        int rank = 0;
        int size = 0;
        try {
            if (mpi) {
                mpiOps = new MpiOps();
                rank = mpiOps.getRank();
                size = mpiOps.getSize();
            }


            List<File> files = new ArrayList<File>();

            List<File> list = new ArrayList<File>();
            Collections.addAll(list, pointInFolder.listFiles());
            Collections.sort(list);
            if (mpi) {
                Iterator<File> datesItr = list.iterator();
                int i = 0;
                while (datesItr.hasNext()) {
                    File next = datesItr.next();
                    if (i == rank) {
                        files.add(next);
                    }
                    i++;
                    if (i == size) {
                        i = 0;
                    }
                }
            } else {
                files.addAll(list);
            }

            processFiles(files);

        } catch (MPIException e) {
            e.printStackTrace();
        }
    }

    private void processFiles(List<File> files) {
        for (int i = 0; i < files.size(); i++) {
            File file = files.get(i);
            // get the filename
            String fileNameWithoutExtension = FilenameUtils.removeExtension(file.getName());
            String distanceFile = distanceFolder + "/" + fileNameWithoutExtension + ".csv";
            String pointFile = pointFolder + "/" + file.getName();

            int noOfLines = readNoOfLines(pointFile);

            SHeatMapGenerator heatMapGenerator = new SHeatMapGenerator(configFile);
            heatMapGenerator._rows = noOfLines;
            heatMapGenerator._cols = noOfLines;
            heatMapGenerator._aMat = pointFile;
            heatMapGenerator._bMat = distanceFile;
            heatMapGenerator._title = fileNameWithoutExtension;
            heatMapGenerator._outdir = outDir;

            heatMapGenerator.process();
        }
    }

    private int readNoOfLines(String file) {
        BufferedReader bufRead = null;
        try {
            bufRead = new BufferedReader(new FileReader(file));
            String inputLine;
            int index = 0;
            while ((inputLine = bufRead.readLine()) != null) {
                index++;
            }
            return index;
        } catch (Exception e) {
            throw new RuntimeException("Faile to read file: " + file, e);
        }
    }
}

