package com.alicorn.service;

import cn.hutool.core.io.FileUtil;
import com.alicorn.util.MyBatisUtil;
import org.apache.ibatis.session.SqlSession;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DataImportHuToolService {
    public void importData(String tableName, String filePath) {
        try (SqlSession session = MyBatisUtil.getSqlSessionFactory().openSession()) {

            File file = FileUtil.file(filePath);
            List<String> lines = FileUtil.readUtf8Lines(file);

            if (!lines.isEmpty()) {
                String[] columns = lines.get(0).split(",");

                for (int i = 1; i < lines.size(); i++) {
                    String[] values = lines.get(i).split(",");
                    Map<String, Object> params = new HashMap<>();
                    params.put("tableName", tableName);
                    params.put("columns", String.join(",", columns));
                    params.put("values", String.join(",", values));

                    session.insert("GenericMapper.insertData", params);
                }
                session.commit();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
