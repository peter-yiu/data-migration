package com.alicorn.service;

import com.alicorn.util.MyBatisUtil;
import org.apache.ibatis.session.SqlSession;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class DataImportService {
    public void importData(String tableName, String filePath) {
        try (SqlSession session = MyBatisUtil.getSqlSessionFactory().openSession();
             BufferedReader reader = new BufferedReader(new FileReader(filePath))) {

            String headerLine = reader.readLine();
            String[] columns = headerLine.split(",");

            String line;
            while ((line = reader.readLine()) != null) {
                String[] values = line.split(",");
                Map<String, Object> params = new HashMap<>();
                params.put("tableName", tableName);
                params.put("columns", String.join(",", columns));
                params.put("values", String.join(",", values));

                session.insert("GenericMapper.insertData", params);
            }
            session.commit();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
