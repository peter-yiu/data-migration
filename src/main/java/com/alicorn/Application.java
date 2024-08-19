package com.alicorn;

import com.alicorn.service.DataExportService;
import com.alicorn.service.DataImportService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);


        if (args.length < 3) {
            System.out.println("Usage: java -jar mybatis-data-migration.jar [export|import] <tableName> <filePath>");
            return;
        }

        String action = args[0];
        String tableName = args[1];
        String filePath = args[2];

        if ("export".equalsIgnoreCase(action)) {
            new DataExportService().exportData(tableName, filePath);
        } else if ("import".equalsIgnoreCase(action)) {
            new DataImportService().importData(tableName, filePath);
        } else {
            System.out.println("Unknown action: " + action);
        }
    }
}


