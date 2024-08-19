package com.alicorn.service;

import com.alicorn.util.MyBatisUtil;
import org.apache.ibatis.session.SqlSession;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class DataExportService {
    public void exportData(String tableName, String filePath) {
        try (SqlSession session = MyBatisUtil.getSqlSessionFactory().openSession();
             BufferedWriter writer = new BufferedWriter(new FileWriter(filePath))) {

            List<Map<String, Object>> results = session.selectList("GenericMapper.selectAll", tableName);
            if (!results.isEmpty()) {
                String header = String.join(",", results.get(0).keySet());
                writer.write(header);
                writer.newLine();

                for (Map<String, Object> row : results) {
                    String line = String.join(",", row.values().stream()
                            .map(value -> value == null ? "" : value.toString())
                            .toArray(String[]::new));
                    writer.write(line);
                    writer.newLine();
                }
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
